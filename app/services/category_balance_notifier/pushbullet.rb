class CategoryBalanceNotifier::Pushbullet
  def initialize(config)
    @client = Washbullet::Client.new(config[:api_key])
  end

  def notify(category_name, category_balance)
    @client.push_note(params: {
      title: title_text(category_name, category_balance),
      body: body_text(category_name, category_balance)
    })
  end

  def title_text(category_name, category_balance)
    "#{category_name} balance remaining: #{category_balance}"
  end

  def body_text(category_name, category_balance)
    "You have #{category_balance} remaining in your #{category_name} category for the rest of the month."
  end
end
