# Hmp

This gem adds ActiveRecord support for partitioned has_one relations using the
PostgreSQL PARTITION BY clause.

## Installation

Add this line to your application's Gemfile:

    gem 'hmp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hmp

## Usage

Suppose you have some Customers, and each Customer has_many SupportTickets. If
SupportTicket has a created_at field, then it might be necessary to ask not just for

    customer.support_tickets

but rather to ask for

    customer.latest_support_ticket

Going 1 Customer at the time, you could easily do

    customer.support_tickets.first(:order => 'id DESC')

but you could not include the association when you load the Customers because
the ORDER BY clause should apply within each unique SupportTicket.customer_id,
not over the whole set of Customers. Using the hmp gem adds support for, e.g.,

    Customer.all(:limit => 10, :include => :latest_support_ticket)

In the Customer model, just add

    include HasManyPartitionable
    has_one_partitionable :latest_support_ticket

Other standard has_one options are supported, so if you wanted to use the name
:most_recent_support_ticket instead, you could use

    include HasManyPartitionable
    has_one_partitionable :most_recent_support_ticket, :class_name => 'SupportTicket'

If :class_name is not given, a class name will be generated by removing every
character up to and including the first underscore.

## Tests

To run the tests, use

    rspec


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
