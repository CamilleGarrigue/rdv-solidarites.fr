class ReminderJob < ApplicationJob
  queue_as :cron

  def perform(*_args)
    Rdv.active.day_after_tomorrow.each { |rdv| rdv.send_reminder if rdv.notify? }
  end
end
