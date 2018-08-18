class CategoryBalanceNotifier
  def initialize
    @services ||= []
  end

  def notify(ynab_category)
    @services.each do |service|
      service.notify(ynab_category.name, formatted_balance(ynab_category.balance))
    end
  end

  def discover_services
    # Pushbullet
    if ENV['PUSHBULLET_API_KEY'].present?
      add_service(CategoryBalanceNotifier::Pushbullet, { api_key: ENV['PUSHBULLET_API_KEY'] })
    end

    # @todo email
    # @todo sms
  end

  private

  # @todo How do we support currencys? May need to call YNAB api and get settings if possible
  def formatted_balance(category_balance)
    "£#{(category_balance / 1000.to_f).round(2)}"
  end

  def add_service(service_class, config = {})
    @services << service_class.new(config)
  end
end
