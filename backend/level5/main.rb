require "json"
require "json-schema"
require_relative "drivy_json"

class Drivy


  #make sure it's ordered by days
  @@DAY_DISCOUNTS = [
    {days: 1, discount: 0.9 },
    {days: 4, discount: 0.7 },
    {days: 10, discount: 0.5 }
  ]


  @data = nil
  @result = nil

  def read_data path
    begin
      res = nil
      json_str = nil
      File.open(path) { |file| json_str = file.read }

      JSON::Validator.validate!(DRIVY_DATA_JSON_SCHEMA, json_str, :strict => true, :version => :draft4)
      res = JSON.parse(json_str, object_class: OpenStruct)
      res.rentals.each do |rental|
        car = res.cars.find { |c| c.id == rental.car_id}
        raise StandardError.new("Rental id #{rental.id} has no car with id #{rental.car_id}") if car.nil?
        rental.car = car
      end

    rescue => e
      STDERR.puts e.message
      return
    end

    @data = res
    compute
  end


  def compute
    result = []

    @data.rentals.each do |rental|
      renting_days = (Date.parse(rental.end_date) - Date.parse(rental.start_date)).to_i + 1
      car = rental.car

      #price computation
      ppk = car.price_per_km * rental.distance

      ppd = 0
      previous_days = 0
      discount = 1
      @@DAY_DISCOUNTS.each do |dd|
        if renting_days > previous_days
          ppd = ppd + car.price_per_day * ([renting_days, dd[:days]].min - previous_days) * discount
        end
        previous_days = dd[:days]
        discount = dd[:discount]
      end
      if renting_days > previous_days
        ppd = ppd + car.price_per_day * (renting_days - previous_days) * discount
      end

      price = ppk.to_i + ppd.to_i

      #deductible computation
      deductible_reduction = 0
      deductible_reduction = renting_days * 400 if rental.deductible_reduction


      #commission computation
      total_commission = (price * 0.3).to_i
      commission = {}

      commission["insurance_fee"] = (total_commission * 0.5).to_i
      commission["assistance_fee"] = renting_days * 100
      commission["drivy_fee"] = total_commission - commission["insurance_fee"] - commission["assistance_fee"]

      result.push({
                    "id" => rental["id"],
                    "actions" => [
                      {
                        "who" => "driver",
                        "type" => "debit",
                        "amount" => price + deductible_reduction
                      },
                      {
                        "who" => "owner",
                        "type" => "credit",
                        "amount" => price - total_commission
                      },
                      {
                        "who" => "insurance",
                        "type" => "credit",
                        "amount" => commission["insurance_fee"]
                      },
                      {
                        "who" => "assistance",
                        "type" =>"credit",
                        "amount" => commission["assistance_fee"]
                      },
                      {
                        "who" => "drivy",
                        "type" => "credit",
                        "amount" => commission["drivy_fee"] + deductible_reduction
                      }
                    ]
      })
    end

    @result = { "rentals" => result }
  end

  def output path
    if @result == nil
      STDERR.puts "There was no data provided or the data provided was invalid."
    else
      _json_str = JSON.pretty_generate(@result)
      begin
        File.write(path, _json_str + "\n")
      rescue => e
        STDERR.puts e.message
      end
    end
  end


end

drivy = Drivy.new

drivy.read_data "data.json"

drivy.output "test.json"
