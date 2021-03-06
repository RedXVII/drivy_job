require "json"
require "json-schema"

JSON_DATE_REGEXP = /\A\d{4}-\d{1,2}-\d{1,2}\z/

def add_json_date_validator

  format_proc = -> value {

    if value.is_a?(String)
      error_message = "Must be a date in the format of YYYY-MM-DD"
      if JSON_DATE_REGEXP.match(value)
        begin
          Date.parse(value)
        rescue ArgumentError => e
          raise JSON::Schema::CustomFormatError.new(error_message)
        end
      else
        raise JSON::Schema::CustomFormatError.new(error_message)
      end
    end
  }

  JSON::Validator.register_format_validator("date", format_proc, ["draft4"])
end

add_json_date_validator

DRIVY_DATA_JSON_SCHEMA = {

  "type"=>"object",
  "required" => ["cars", "rentals"],
  "properties" => {
    "cars" => {
      "type" => "array",
      "items" => {
        "type" => "object",
        "required" => ["id", "price_per_day", "price_per_km"],
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
        "required" => ["id", "car_id", "distance", "start_date", "end_date", "deductible_reduction"],
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
            "type" => "string",
            "format" => "date"
          },
          "end_date" => {
            "type" => "string",
            "format" => "date"
          },
          "deductible_reduction" => {
            "type" => "boolean"
          }
        }
      }
    },
    "rental_modifications" => {
      "type" => "array",
      "items" => {
        "type" => "object",
        "required" => ["id", "rental_id"],
        "properties" => {
          "id" => {
            "type" => "integer"
          },
          "rental_id" => {
            "type" => "integer"
          },
          "distance" => {
            "type" => "integer"
          },
          "start_date" => {
            "type" => "string",
            "format" => "date"
          },
          "end_date" => {
            "type" => "string",
            "format" => "date"
          },
          "deductible_reduction" => {
            "type" => "boolean"
          }
        }
      }
    }
  }
}
