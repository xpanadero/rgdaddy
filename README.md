# RGDaddy

Welcome to RGDaddy gem! This gem allows you to interact with GoDaddy DNS Panel.
At the beginning was created as an option to use GoDaddy as a Dynamic DNS Server.

Actualy it only suport modifying A records.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rgdaddy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rgdaddy

## Usage

```require 'rgdaddy'

# Create a RGDaddy object
r=RGDaddy::RGDaddy.new;

# Then login to GoDaddy
r.login('RGDADDY_USER','RGDADDY_PASSWORD');

# Recover GoDaddy DNS A records as RGDaddy::Record array
result=r.get_dns_records("ZONE_NAME.COM","A")

# Print the array
result.each { |f|
   puts f
}

# Update DNS records with update_dns_record(ZONE_NAME,RECORD_ID,HOSTNAME,IP,TTL,RECORD_TYPE)
r.update_dns_record("ZONE_NAME.com",7,"A_HOSTNAME","127.0.0.1",600,"A")


# Close GoDaddy session
r.logout()

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release` to create a git tag for the version, push git
commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/xpanadero/rgdaddy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
