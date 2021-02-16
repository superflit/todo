require 'test_helper'

class PostgresTest < ActiveSupport::TestCase  # :nodoc:

  PLAIN_CONFIG = { adapter: "postgresql", host: "localhost", database: "apa_pg_test" }

  class Dog < ActiveRecord::Base
    establish_connection PLAIN_CONFIG
  end

  # unless Dog.connection.tables.include?('dogs')
  #   ActiveRecord::Schema.define do
  #     create_table :dogs do |table|
  #       table.column :name, :string
  #     end
  #   end
  # end
  #
  # test "postgres model" do
  #   assert Dog.count == 0
  # end


end
