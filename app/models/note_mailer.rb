class NoteMailer < ActionMailer::Base

  # send an email to someone that submits a note
  # asking them to confirm 
  def confirm(sent_at = Time.now)
    @subject    = 'NoteMailer#confirm'
    @body       = {}
    @recipients = ''
    @from       = ''
    @sent_on    = sent_at
    @headers    = {}
  end
 
  # send an email to administrators
  # letting them know that something happehed
  def admin(sent_at = Time.now)
    @subject    = 'NoteMailer#admin'
    @body       = {}
    @recipients = ''
    @from       = ''
    @sent_on    = sent_at
    @headers    = {}
  end
end
