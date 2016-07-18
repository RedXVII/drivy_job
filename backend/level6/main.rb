require "json"
require "json-schema"
require_relative "drivy_json"
require_relative "rental"




class Drivy

  @data = nil
  @result = nil

  def read_data path
    begin
      res = nil
      json_str = nil
      File.open(path) { |file| json_str = file.read }

      JSON::Validator.validate!(DRIVY_DATA_JSON_SCHEMA, json_str, :version => :draft4)
      res = JSON.parse(json_str, object_class: OpenStruct)
      res.rentals.each do |rental|
        car = res.cars.find { |c| c.id == rental.car_id}
        raise StandardError.new("Rental id #{rental.id} has no car with id #{rental.car_id}") if car.nil?
        rental.car = car
      end

      res.rental_modifications.each do |rental_modification|
        rental = res.rentals.find { |r| r.id == rental_modification.rental_id}
        raise StandardError.new("Rental modification id #{rental_modification.id} has no rental with id #{rental_modification.rental_id}") if rental.nil?
        rental_modification.rental = rental
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
    rentals = {}

    @data.rentals.each do |rental_data|
      rental = Rental.new rental_data
      rentals[rental.id] = rental
    end

    @data.rental_modifications.each do |rental_modification|
      rental = rentals[rental_modification.rental_id]

      delta_actions = rental.update rental_modification

      result.push(
        {
          "id" => rental_modification.id,
          "rental_id" => rental_modification.rental_id,
          "actions" => delta_actions
      })
    end

    @result = { "rental_modifications" => result }
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
