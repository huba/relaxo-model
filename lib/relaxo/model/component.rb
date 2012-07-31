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

require 'relaxo/model/base'

module Relaxo
	module Model
		class Error
			def initialize(key, exception)
				@key = key
				@exception = exception
			end
			
			attr :key
			attr :exception
		end
		
		module Component
			def self.included(child)
				# $stderr.puts "#{self} included -> #{child} extend Base"
				child.send(:extend, Base)
			end
			
			def initialize(database, attributes = {})
				# Raw key-value database
				@attributes = attributes
				@database = database
				@changed = {}
			end

			attr :attributes
			attr :database
			attr :changed

			def clear(key)
				@changed.delete(key)
				@attributes.delete(key)
			end

			def assign(primative_attributes, only = :all)
				enumerator = primative_attributes

				if only == :all
					enumerator = enumerator.select{|key, value| self.class.properties.include? key.to_s}
				elsif only.respond_to? :include?
					enumerator = enumerator.select{|key, value| only.include? key.to_sym}
				end

				enumerator.each do |key, value|
					key = key.to_s

					klass = self.class.properties[key]

					if klass
						# This might raise a validation error
						value = klass.convert_from_primative(@database, value)
					end

					self[key] = value
				end
			end

			def [] name
				name = name.to_s

				if self.class.properties.include? name
					self.send(name)
				else
					raise KeyError.new(name)
				end
			end

			def []= name, value
				name = name.to_s

				if self.class.properties.include? name
					self.send("#{name}=", value)
				else
					raise KeyError.new(name)
				end
			end

			def flatten!
				errors = []

				# Flatten changed properties:
				self.class.properties.each do |key, klass|
					if @changed.include? key
						if klass
							begin
								@attributes[key] = klass.convert_to_primative(@changed.delete(key))
							rescue StandardError => error
								errors << Error.new(key, error)
							end
						else
							@attributes[key] = @changed.delete(key)
						end
					end
				end

				# Non-specific properties, serialised by JSON:
				@changed.each do |key, value|
					@attributes[key] = value
				end

				@changed = {}

				errors
			end
			
			def to_hash
				@attributes
			end
		end
	end
end