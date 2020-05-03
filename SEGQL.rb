#!/usr/bin/ruby
require './Query.rb'

query = Query.new()
query.set_key()

if query.read()
    if query.get_function() == 'select'
        if query.validate_attributes()
            if query.validate_url()
                query.set_params()
                blocks = query.get_blocks()
                if blocks
                    result = query.select_blocks(blocks)
                    query.show_table(result)
                else
                    puts 'Segmentation error'
                end
            else
                puts 'Invalid URL'
            end
        else
            puts 'Invalid attributes'
        end
    elsif query.get_function() == 'merge'
        if query.validate_attributes()
            if query.validate_url()
                query.set_params()
                blocks = query.get_blocks()
                if blocks
                    result = query.merge_blocks(blocks)
                    query.show_table(result)
                else
                    puts 'Segmentation error'
                end
            else
                puts 'Invalid URL'
            end
        else
            puts 'Invalid attributes'
        end
    else
        puts 'Invalid function'
    end
else
    puts 'Invalid query'
end