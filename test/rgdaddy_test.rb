require 'minitest_helper'

class TestRgdaddy < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RGDaddy::VERSION
  end

  def test_invalid_godaddy_login
      r=RGDaddy::RGDaddy.new
      e=assert_raises(RGDaddy::RGDaddyException) {
        r.login("user","password")
      }
      assert_equal e.message, "Invalid authentication credentials"
  end

  def test_update_unsuported_records_should_fail
      r=RGDaddy::RGDaddy.new
      e=assert_raises(RGDaddy::RGDaddyException) {
        r.update_dns_record("test_zone",1,"host_name","1.1.1.2",600,"INVALID_TYPE")
      }
      assert_equal e.message, "Only A record type is currently supported"
  end

  def test_login_required_previous_update_record
      r=RGDaddy::RGDaddy.new
      e=assert_raises(RGDaddy::RGDaddyException) {
        r.update_dns_record("test_zone",1,"host_name","1.1.1.2",600,"A")
      }
      assert_equal e.message, "Not logged in, please call login method first"
    # assert RGDaddy.update_record("10.1.1.1");

  end
end
