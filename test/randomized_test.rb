# Copyright (c) 2007, 2008 Pythonic Pty. Ltd. http://www.pythonic.com.au/

ENV["RAILS_ENV"] ||= "test"

require "config/environment"
require "test_help"

class Test::Unit::TestCase
  self.use_transactional_fixtures = true
end

class RandomizedTestMigration < ActiveRecord::Migration
  def self.up
    create_table :randomized_test_users do |t|
      t.column :name, :string, :null => false
    end
  end

  def self.down
    drop_table :randomized_test_users
  end
end

RandomizedTestMigration.migrate :up

at_exit do
  at_exit do
    RandomizedTestMigration.migrate :down
  end
end

class RandomizedTestUser < ActiveRecord::Base
  cattr_accessor :randomized_callbacks
  before_create { self.randomized_callbacks = [randomized_callbacks] }
  cattr_accessor :randomized_id
  acts_as_randomized(:times => 1) { self.randomized_id += 1 }
end

class RandomizedTest < Test::Unit::TestCase
  def test_retains_given_id
    RandomizedTestUser.randomized_id = 17
    u19 = RandomizedTestUser.new :name => "19"
    u19.id = 19
    u19.save
    assert_equal 19, u19.id
  end

  def test_generates_id_on_create
    RandomizedTestUser.randomized_id = 17
    u18 = RandomizedTestUser.create :name => "18"
    assert_equal 18, u18.id
  end

  def test_retries_on_duplicate_key_error
    RandomizedTestUser.randomized_id = 17
    u18 = RandomizedTestUser.create :name => "18"
    RandomizedTestUser.randomized_id = 17
    u19 = RandomizedTestUser.create :name => "19"
    assert_equal 19, u19.id
  end

  def test_raises_error
    RandomizedTestUser.randomized_id = 17
    u18 = RandomizedTestUser.create :name => "18"
    RandomizedTestUser.randomized_id = 17
    u19 = RandomizedTestUser.create :name => "19"
    RandomizedTestUser.randomized_id = 17
    assert_raises ActiveRecord::RandomizedError do
      u20 = RandomizedTestUser.create :name => "20"
    end
  end

  def test_invokes_callbacks
    RandomizedTestUser.randomized_callbacks = nil
    RandomizedTestUser.randomized_id = 17
    u18 = RandomizedTestUser.create :name => "18"
    assert_equal [nil], RandomizedTestUser.randomized_callbacks
    RandomizedTestUser.randomized_id = 17
    u19 = RandomizedTestUser.create :name => "19"
    assert_equal [[nil]], RandomizedTestUser.randomized_callbacks
    RandomizedTestUser.randomized_id = 17
    begin
      u20 = RandomizedTestUser.create :name => "20"
    rescue ActiveRecord::RandomizedError
    end
    assert_equal [[[nil]]], RandomizedTestUser.randomized_callbacks
  end
end
