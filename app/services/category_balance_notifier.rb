class CategoryBalanceNotifier

  def initialize
    @services ||= []
    discover_services
  end

  def notify(category_name, category_balance)
    @services.each do |service|
      service.notify(category_name, category_balance)
    end
  end

  private

  def add_service(service_class, config = {})
    @services << service_class.new(config)
  end

  def discover_services
    # Pushbullet
    if ENV['PUSHBULLET_API_KEY'].present?
      add_service(CategoryBalanceNotifier::Pushbullet, {
        api_key: ENV['PUSHBULLET_API_KEY']
      })
    end

    # @todo email
    # @todo sms
  end
end
