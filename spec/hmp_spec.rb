require 'active_record'
require 'hmp'
require 'yaml'

# Connect to the database.
$db_info = YAML.load_file('database.yml')
puts $db_info
ActiveRecord::Base.establish_connection($db_info)

# Build the tables. This would be done via migrations if we were using a full
# Rails install.
ActiveRecord::Base.connection.execute(%{
  DROP TABLE IF EXISTS support_tickets;
  DROP TABLE IF EXISTS customers;
  CREATE TABLE customers (
    id          integer PRIMARY KEY DEFAULT nextval('serial'),
    created_at  timestamp without time zone NOT NULL,
    updated_at  timestamp without time zone NOT NULL,
    name        text NOT NULL
  );
  CREATE TABLE support_tickets (
    id           integer PRIMARY KEY DEFAULT nextval('serial'),
    created_at   timestamp without time zone NOT NULL,
    updated_at   timestamp without time zone NOT NULL,
    customer_id  integer NOT NULL REFERENCES customers(id),
    message      text NOT NULL
  );
  CREATE INDEX index_support_tickets_on_customer_id ON support_tickets(customer_id) CLUSTER;
})

# Define the models.
class Customer < ActiveRecord::Base
  validates_presence_of :name, :allow_blank => false
  include HasManyPartitionable
  has_one_partitionable :latest_support_ticket
end
class SupportTicket < ActiveRecord::Base
  validates_numericality_of :customer_id, :gt => 0, :only_integer => true
  validates_presence_of :message, :allow_blank => false
  belongs_to :customer
end

# Populate some data.
barney = Customer.create!(:name => 'Barney')
[%{You know who's confused?},
 %{Did I pick the right tie?}].each do |msg|
  SupportTicket.create!(:customer_id => barney.id, :message => msg)
end

describe Hmp::Hmp do
  it "should get all of Barney's SupportTickets" do
    barney.support_tickets.count.should eql(2)
    barney.support_tickets.all.map(&:class).map(&:to_s).each do |st_klass|
      st_klass.should eql('SupportTicket')
    end
  end

  it "should get Barney's latest SupportTicket" do
    barney.latest_support_ticket.class.to_s.should eql('SupportTicket')
    barney.latest_support_ticket.id.should eql(barney.support_tickets.first(:order => 'id DESC'))
  end
end
