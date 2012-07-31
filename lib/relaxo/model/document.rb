# Copyright (c) 2012 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'relaxo/model/component'

module Relaxo
	module Model
		class ValidationErrors < StandardError
			def self.message_for_errors(errors)
				errors.map{|error| "#{error.key} (#{error.exception.message})"}.join(', ')
			end
			
			def initialize(errors)
				super "Model validation errors occurred: #{self.class.message_for_errors(errors)}"
				
				@errors = errors
			end
			
			attr :errors
		end
		
		module Document
			TYPE = 'type'
			
			def self.included(child)
				# $stderr.puts "#{self} included -> #{child} extend ClassMethods"
				child.send(:include, Component)
				child.send(:extend, ClassMethods)
			end
			
			module ClassMethods
				def create(database, properties = nil)
					instance = self.new(database, {TYPE => @type})

					if properties
						properties.each do |key, value|
							instance[key] = value
						end
					end

					instance.after_create

					return instance
				end

				def fetch(database, id_or_attributes)
					if Hash === id_or_attributes
						instance = self.new(database, id_or_attributes)
					else
						instance = self.new(database, database.get(id_or_attributes).to_hash)
					end

					instance.after_fetch

					return instance
				end
			end
			
			include Comparable
			
			def id
				@attributes[ID]
			end

			def saved?
				@attributes.key? ID
			end

			def rev
				@attributes[REV]
			end

			def type
				@attributes[TYPE]
			end

			# Update any calculations:
			def before_save
			end

			def after_save
			end

			# Reconnect this document with a new database session, typically used for updating an existing model within a session. Changes to the original object may be lost.
			def attach(database)
				clone = self.class.new(database, @attributes.dup)
				
				clone.after_fetch
				
				return clone
			end

			def save
				before_save

				errors = self.flatten!
				raise ValidationErrors.new(errors) if errors.size > 0

				@database.save(@attributes)

				after_save
			end

			def before_delete
			end

			def after_delete
			end

			def delete
				before_delete

				@database.delete(@attributes)

				after_delete
			end

			def after_fetch
			end

			# Set any default values:
			def after_create
			end
			
			# Equality is done only on id
			def <=> other
				self.id <=> other.id
			end
		end
	end
end