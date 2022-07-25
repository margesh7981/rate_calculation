# RateCalulation

Finding cheapest rate between origin and destianation

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rate_calculation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rate_calculation

## Usage

Finding cheapest rate between origin and destianation


1. Return the cheapest direct sailing 
   
   RateCalculation::GetRate.new("CNSHA","NLRTM").cheapest_direct_sailing

2 . Return the cheapest direct or indirect sailing 

  RateCalculation::GetRate.new("CNSHA","NLRTM").cheapest_direct_or_indirect_sailing
  
3. Return the cheapest direct or indirect fastest sailing legs

   RateCalculation::GetRate.new("CNSHA","NLRTM").fastest_sailing_legs
  
## Contributing

1. Fork it ( https://github.com/[my-github-username]/rate_calcualtion/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
