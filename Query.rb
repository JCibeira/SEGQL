require 'json'
require 'terminal-table'
require './Globals.rb'

class Query
    def initialize()
        @function = ''
        @attributes = ''
        @from = ''
        @url = ''
        @condition = ''
        @order_by = ''
        @params = ''

        @segment_params = {
            'ptype' => 'ffront', 
            'dc' => 30,
            'area' => 0,
            'categories' => 'FLOW',
            'method' => 'html5',
            'granmethod' => 'frec',
            'align' => 'HVL',
            'pa' => 5
        }
    end

    def set_key()
        if $KEY == ''
            $KEY = bom_open()
        end
        @segment_params['key'] = $KEY
    end

    def process_attrs_params(data)
        if data.include?(' ')
            data.delete!(' ')
        end

        if data.include?(',')
            data = data.split(',')
        else
            return [data]
        end

        return data
    end

    def read()
        # Reading obligatory lines
        @function = gets.chomp
        @attributes = process_attrs_params(gets.chomp)
        @from = gets.chomp
        @url = gets.chomp

        last_line = @url.include?(';')
        actual_line = 0

        # Reading optional lines
        if last_line
            @url.delete!(';')
        else
            while !last_line
                line_function = gets.chomp
                line_value = gets.chomp
                last_line = line_value.include?(';')

                if line_function == 'where' && actual_line == 0
                    # Read where
                    actual_line = 1
                    @condition = last_line ? line_value.delete!(';') : line_value
                elsif line_function == 'order by' && actual_line <= 1
                    # Read order by
                    actual_line = 2
                    @order_by = last_line ? line_value.delete!(';') : line_value
                elsif line_function == 'params' && actual_line <= 2
                    # Read params
                    if last_line
                        @params = process_attrs_params(line_value.delete!(';'))
                    else
                        return false
                    end
                else
                    return false
                end
            end
        end
        return true
    end

    def get_function()
        return @function
    end
    
    def validate_attributes()
        if @attributes.length > 1 && @attributes.include?('*')
            return false
        end

        @attributes.each do |value|
            if !$VALID_ATTRIBUTES.include?(value)
                return false
            end
        end

        return true
    end

    def validate_params()
        @params.each do |value|
            if !$VALID_PARAMS.include?(value)
                return false
            end
        end
        return true
    end

    def validate_url()
        return @url =~ URI::regexp
    end
    
    def set_params()
        @segment_params['url'] = @url
        
        @params.each do |param|
            prm = param.split('=')
            if prm[0] == 'dc' || prm[0] == 'pa'
                @segment_params[prm[0]] = prm[1].to_i
            elsif prm[0] == 'area'
                @segment_params[prm[0]] = prm[1].to_f
            else
                @segment_params[prm[0]] = prm[1]
            end
        end
    end

    def select_blocks()
        if($STATUS != 'data stored in Cache')
            if(get_request('segment', @segment_params))
                $STATUS = 'data stored in Cache'
            else
                return false
            end
        end

        rows = []

        blocks = bom_json(@segment_params['key'])

        blocks.each do |block|
            if @condition == '' || where(block, @condition)
                row = []
                @attributes.each do |attribute|
                    if attribute == '*'
                        row.push(block['bid'])
                        row.push(verify_length(block['label']))
                        row.push(verify_length(block['text']))
                        row.push(verify_length(block['images']))
                        row.push(block['pa'])
                        row.push(block['density'])
                        row.push(block['area'])
                        row.push(block['rectangle'])
                        row.push(block['parent'])
                    else
                        row.push(verify_length(block[attribute]))
                    end
                end
                rows.push(row)
            end
        end

        table = Terminal::Table.new :headings => (@attributes[0] == '*' ? $VALID_ATTRIBUTES.drop(1) : @attributes), :rows => rows
        table.style = { :all_separators => true }

        puts table

        return true
    end

    def where(block, line)
        conditions = line.split()
        operator = ''
        result = false
        logic = 'or'
        check = false

        conditions.each do |condition|
            if condition == 'and'
                logic = 'and'
            elsif condition == 'or'
                logic = 'or'
            else
                if condition.include?('<=')
                    params = condition.split('<=')
                    values_to_compare = convert_type(params, block[params[0]])
                    check = values_to_compare[0] <= values_to_compare[1]
                elsif condition.include?('>=')
                    params = condition.split('>=')
                    values_to_compare = convert_type(params, block[params[0]])
                    check = values_to_compare[0] >= values_to_compare[1]
                elsif condition.include?('!=')
                    params = condition.split('!=')
                    values_to_compare = convert_type(params, block[params[0]])
                    check = values_to_compare[0] != values_to_compare[1]
                elsif condition.include?('=')
                    params = condition.split('=')
                    values_to_compare = convert_type(params, block[params[0]])
                    check = values_to_compare[0] == values_to_compare[1]
                elsif condition.include?('>')
                    params = condition.split('>')
                    values_to_compare = convert_type(params, block[params[0]])
                    check = values_to_compare[0] > values_to_compare[1]
                elsif condition.include?('<')
                    params = condition.split('<')
                    values_to_compare = convert_type(params, block[params[0]])
                    check = values_to_compare[0] < values_to_compare[1]
                end
    
                if logic == 'and'
                    result = result && check
                else
                    result = result || check
                end
            end
        end
    
        return result
    end

    def merge_blocks()
        
    end
end