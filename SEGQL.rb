#!/usr/bin/ruby
require './Query.rb'

query = Query.new()
query.set_key()

if query.read()
    if query.get_function() == 'select'
        if query.validate_attributes()
            if query.validate_url()
                query.set_params()
                if !query.select_blocks()
                    puts 'Segmentation error'
                end
            else
                puts 'Invalid URL'
            end
        else
            puts 'Invalid attributes'
        end
    elsif query.get_function() == 'merge'
        query.merge_blocks()
    else
        puts 'Invalid function'
    end
else
    puts 'Invalid query'
end