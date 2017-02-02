# Relaxo Model

Relaxo Model provides a framework for business logic on top of Relaxo, a document data store built on top of git. While it supports some traditional relational style patterns, it is primary focus is to model business processes and logic at the document level.

[![Build Status](https://secure.travis-ci.org/ioquatix/relaxo-model.svg)](http://travis-ci.org/ioquatix/relaxo-model)
[![Code Climate](https://codeclimate.com/github/ioquatix/relaxo-model.svg)](https://codeclimate.com/github/ioquatix/relaxo-model)
[![Coverage Status](https://coveralls.io/repos/ioquatix/relaxo-model/badge.svg)](https://coveralls.io/r/ioquatix/relaxo-model)

## Basic Usage

Here is a simple example of a traditional ORM style model:

	require 'relaxo/model'

	database = Relaxo.connect("test")

	trees = [
		{:name => 'Hinoki', :planted => Date.parse("1948/4/2")},
		{:name => 'Rimu', :planted => Date.parse("1962/8/7")}
	]
	
	class Tree
		include Relaxo::Model
		
		property :id, UUID
		property :name
		property :planted, Attribute[Date]
	
		# Ensure you've loaded an appropriate design document:
		view :all, 'catalog/tree', Tree
	end
	
	database.transaction("Create trees") do |dataset|
		trees.each do |doc|
			tree = Tree.create(dataset, doc)
		
			tree.save
		end
	end
	
	database.head do |dataset|
		Tree.all(dataset).each do |tree|
			puts "A #{tree.name} was planted on #{tree.planted.to_s}."

			# Expected output:
			# => A Rimu was planted on 1962-08-07.
			# => A Hinoki was planted on 1948-04-02.
		
			tree.delete
		end
	end
	
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2010-2013, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
