# Copyright (c) 2007, 2008 Pythonic Pty. Ltd. http://www.pythonic.com.au/

module ActiveRecord
  # Raised when duplicate primary key retries are exhausted.
  class RandomizedError < StandardError
  end
end

module ActiveRecord::Acts
  module Randomized
    def self.included(base)
      base.extend(ClassMethods)
    end

    # This act implements randomized primary keys. It calls a given proc to
    # generate a primary key on record create and retries if a duplicate
    # primary key error is raised.

    # Example:
    #   class User < ActiveRecord::Base
    #     acts_as_randomized { rand(900_000_000) + 100_000_000 }
    #   end

    module ClassMethods
      # +block+ is a proc to generate a primary key.
      # The +options+ hash can contain:
      #   <tt>:times</tt> -- number of times to retry (default 32).
      def acts_as_randomized(options = {}, &block)
        cattr_accessor :randomized_proc
        cattr_accessor :randomized_times
        self.randomized_proc = block
        self.randomized_times = options[:times] || 32
        class_eval do
          include ActiveRecord::Acts::Randomized::InstanceMethods
          alias_method_chain :create_without_callbacks, :randomized
          set_sequence_name nil
        end
      end
    end

    module InstanceMethods
      def create_without_callbacks_with_randomized
        return create_without_randomized if id
        connection.retry_on_duplicate_primary_key(randomized_times) do
          self.id = randomized_proc.call(self)
          create_without_callbacks_without_randomized
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::Acts::Randomized
