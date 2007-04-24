require File.dirname(__FILE__) + '/../test_helper'
require 'note_mailer'

class NoteMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_confirm
    @expected.subject = 'NoteMailer#confirm'
    @expected.body    = read_fixture('confirm')
    @expected.date    = Time.now

    assert_equal @expected.encoded, NoteMailer.create_confirm(@expected.date).encoded
  end

  def test_admin
    @expected.subject = 'NoteMailer#admin'
    @expected.body    = read_fixture('admin')
    @expected.date    = Time.now

    assert_equal @expected.encoded, NoteMailer.create_admin(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/note_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
