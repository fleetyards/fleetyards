# frozen_string_literal: true

class AdminMailerPreview < ActionMailer::Preview
  def weekly
    stats = {
      registrations: 1,
      ships: 2,
      vehicles: 3
    }

    AdminMailer.weekly(stats)
  end

  def missing_loaners
    loaners = [
      { name: 'Mole Carbon Edition', loaners: ['F7C - Hornet'] },
      { name: 'Mole Talus Edition', loaners: ['F7C - Hornet'] }
    ]

    models = [
      { model: 'Mole Carbon Edition', model_id: 'a0e410d2-f6c2-45aa-a6e2-41dd468dfcf8', loaner: 'F7C - Hornet' },
      { model: 'Mole Talus Edition', model_id: 'ce08abf3-229b-4c4a-9fbd-01519a85893a', loaner: 'F7C - Hornet' },
      { model: 'Mole', model_id: 'c521edf2-7e0a-405e-b366-5bc76c165cb6', loaner: 'F7C - Hornet' }
    ]

    AdminMailer.missing_loaners(loaners, models)
  end

  def notify_block
    AdminMailer.notify_block('https://foo.bar')
  end

  def notify_unblock
    AdminMailer.notify_unblock('https://foo.bar')
  end
end
