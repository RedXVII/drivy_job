class Rental

  #make sure it's ordered by days
  @@DAY_DISCOUNTS = [
    {days: 1, discount: 0.9 },
    {days: 4, discount: 0.7 },
    {days: 10, discount: 0.5 }
  ]

  attr_reader :id

  @data = nil

  def initialize data
    @data = data
    @id = data.id
    compute
  end

  def compute
    @renting_days = (Date.parse(@data.end_date) - Date.parse(@data.start_date)).to_i + 1
    car = @data.car

    #price computation
    @price_per_km = (car.price_per_km * @data.distance).to_i

    ppd = 0
    previous_days = 0
    discount = 1
    @@DAY_DISCOUNTS.each do |dd|
      if @renting_days > previous_days
        ppd = ppd + car.price_per_day * ([@renting_days, dd[:days]].min - previous_days) * discount
      end
      previous_days = dd[:days]
      discount = dd[:discount]
    end
    if @renting_days > previous_days
      ppd = ppd + car.price_per_day * (@renting_days - previous_days) * discount
    end

    @price_per_day = ppd.to_i

    @total_price = @price_per_km + @price_per_day

    #deductible computation
    @deductible_reduction = 0
    @deductible_reduction = @renting_days * 400 if @data.deductible_reduction


    #commission computation
    @total_commission = (@total_price * 0.3).to_i

    @insurance_fee = (@total_commission * 0.5).to_i
    @assistance_fee = @renting_days * 100
    @drivy_fee = @total_commission - @insurance_fee - @assistance_fee


  end

  def update update_data
    previous_actions = actions

    @data.start_date = update_data.start_date unless update_data.start_date.nil?
    @data.end_date = update_data.end_date unless update_data.end_date.nil?
    @data.distance = update_data.distance unless update_data.distance.nil?

    compute

    delta_actions(previous_actions, actions)
  end


  def actions
    [
      {
        "who" => "driver",
        "type" => "debit",
        "amount" => @total_price + @deductible_reduction
      },
      {
        "who" => "owner",
        "type" => "credit",
        "amount" => @total_price - @total_commission
      },
      {
        "who" => "insurance",
        "type" => "credit",
        "amount" => @insurance_fee
      },
      {
        "who" => "assistance",
        "type" =>"credit",
        "amount" => @assistance_fee
      },
      {
        "who" => "drivy",
        "type" => "credit",
        "amount" => @drivy_fee + @deductible_reduction
      }
    ]
  end

  def delta_actions previous_actions, updated_actions
    res = []
    previous_actions.zip(updated_actions).each do |previous, updated|
      delta = updated.clone
      delta["amount"] = updated["amount"] - previous["amount"]
      if delta["amount"] < 0
        if delta["type"] == "credit"
          delta["type"] = "debit"
        else
          delta["type"] = "credit"
        end
        delta["amount"] = -delta["amount"]
      end
      res.push delta
    end
    res
  end

end
