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
    id          SERIAL,
    created_at  timestamp without time zone NOT NULL,
    updated_at  timestamp without time zone NOT NULL,
    name        text NOT NULL
  );
  ALTER TABLE customers ADD PRIMARY KEY (id);
  CREATE TABLE support_tickets (
    id           SERIAL,
    created_at   timestamp without time zone NOT NULL,
    updated_at   timestamp without time zone NOT NULL,
    customer_id  integer NOT NULL REFERENCES customers(id),
    message      text NOT NULL
  );
  ALTER TABLE support_tickets ADD PRIMARY KEY (id);
  CREATE INDEX index_support_tickets_on_customer_id ON support_tickets(customer_id);
  CLUSTER support_tickets USING index_support_tickets_on_customer_id;
})
ActiveRecord::Base.connection.execute(%{
  CLUSTER;
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

describe Hmp do
  it "should get all of Barney's SupportTickets" do
    barney.support_tickets.count.should eql(2)
    barney.support_tickets.all.each do |st|
      st.class.to_s.should eql('SupportTicket')
      st.customer_id.should eql(barney.id)
    end
  end

  it "should get Barney's latest SupportTicket" do
    barney.latest_support_ticket.class.to_s.should eql('SupportTicket')
    barney.latest_support_ticket.id.should eql(barney.support_tickets.first(:order => 'id DESC').id)
  end

  it "should get Barney's latest SupportTicket with _fast" do
    barney.latest_support_ticket_fast.class.to_s.should eql('SupportTicket')
    barney.latest_support_ticket_fast.id.should eql(barney.support_tickets.first(:order => 'id DESC').id)
  end
end
