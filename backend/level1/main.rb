require "json"
require "json-schema"


class Drivy

  @@schema = {

    "type"=>"object",
    "properties" => {
      "cars" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "id" => {
              "type" => "integer"
            },
            "price_per_day" => {
              "type" => "integer"
            },
            "price_per_km" => {
              "type" => "integer"
            }
          }
        }
      },
      "rentals" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "id" => {
              "type" => "integer"
            },
            "car_id" => {
              "type" => "integer"
            },
            "distance" => {
              "type" => "integer"
            },
            "start_date" => {
              "type" => "date"
            },
            "end_date" => {
              "type" => "date"
            }
          }
        }
      }
    }
  }


  @data = nil
  @result = nil

  def read_data path
    begin
      res = nil
      File.open(path) { |file| res = JSON.parse(file.read) }
      JSON::Validator.validate!(res, @@schema, :strict => true)
      @data = res
    rescue => e
      STDERR.puts e.message
      return
    end
    compute
  end


  def compute
    result = []

    @data["rentals"].each do |rental|
      renting_days = (Date.parse(rental["end_date"]) - Date.parse(rental["start_date"])).to_i + 1
      car = @data["cars"].find { |c| c["id"] == rental["car_id"]}
      ppk = car["price_per_km"] * rental["distance"]
      ppm = car["price_per_day"] * renting_days
      result.push({"id" => rental["id"], "price" => ppk + ppm})
    end
    @result = { "rentals" => result }

  end

  def output path
    if @result == nil
      STDERR.puts "There was no data provided or the data provided was invalid."
    else
      _json_str = JSON.pretty_generate(@result)
      begin
        File.write(path, _json_str)
      rescue => e
        STDERR.puts e.message
      end
    end
  end


end

drivy = Drivy.new

drivy.read_data "data.json"

drivy.output "output.json"
