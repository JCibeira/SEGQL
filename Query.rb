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
        
        if @params != ''
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

    def order_by(rows, line)
        if line.include?(',')
            line = line.split(',')
        else
            line = [line]
        end

        sort_directions = []

        line.each do |order|
            values = order.split()
            
            if @attributes.length == 1 && @attributes[0] == '*'
                index = $VALID_ATTRIBUTES.drop(1).find_index(values[0])
            else
                index = @attributes.find_index(values[0])
            end

            if values.length == 1 || values[1] == 'asc'
                direction = 1
            elsif values[1] == 'desc'
                direction = -1
            else
                direction = nil
            end

            if index != nil && direction != nil
                sort_directions.push( { :index => index, :order => direction })
            end
        end

        return rows.sort { |a, b|
            keys = sort_directions.map{|val| val[:order] * (a[val[:index]] <=> b[val[:index]])}
            keys.find{ |x| x != 0 } || 0
        }
    end

    def merge_areas(blocks)
        blocks = blocks.sort_by { |block| -1*(block['area']) }  
        min_area_acum = blocks[blocks.length() - 1]['area']
        max_area_acum = blocks.inject(0){|sum, block| sum + block['area'].to_f}
        increment = (max_area_acum - min_area_acum) / 10.0

        x = 1
        acum = min_area_acum
        areas = []

        while x <= 10
            acum += increment
            areas.push(acum)
            x += 1
        end

        return areas
    end

    def get_blocks()
        # if($STATUS != 'data stored in Cache')
        #     if(get_request('segment', @segment_params))
        #         $STATUS = 'data stored in Cache'
        #     else
        #         return false
        #     end
        # end
        
        # return bom_json(@segment_params['key'])
        return file_json()
    end

    def select_blocks(blocks)
        rows = []

        blocks.each do |block|
            if @condition == '' || where(block, @condition)
                row = []
                @attributes.each do |attribute|
                    if attribute == '*'
                        $VALID_ATTRIBUTES.drop(1).each do |valid_attr|
                            row.push(verify_attr(block[valid_attr]))
                        end
                    else
                        row.push(verify_attr(block[attribute]))
                    end
                end
                rows.push(row)
            end
        end

        if @order_by != '' && @function == 'select'
            rows = order_by(rows, @order_by)
        end

        return rows
    end

    def merge_blocks(blocks)
        rows = select_blocks(blocks)
        areas = merge_areas(blocks);
        merges = []
        merge = []

        if rows
            @attributes.each_with_index do |attribute, index|
                concat = ''
                acum = 0

                if attribute == 'bid'
                    bid = rows[0][index] + ' - ' + rows[rows.length() - 1][index]
                    merge.push(bid)
                else
                    rows.each do |row|
                        if attribute == 'label' || attribute == 'text' || attribute == 'images' || attribute == 'parent'
                            concat = concat + ' ' + row[index]
                        else
                            acum = acum + row[index]
                            concat = acum.to_s
                        end
                    end
                    merge.push(concat)
                end
            end

            merges.push(merge)

            x = 0
            index_pa = @attributes.find_index('pa')
            index_area = @attributes.find_index('area')

            while areas[x] < merges[0][index_area].to_f
                x += 1
            end

            merges[0][index_pa] = x + 1

            return merges
        else
            return false
        end
    end

    def show_table(rows)
        table = Terminal::Table.new :headings => (@attributes[0] == '*' ? $VALID_ATTRIBUTES.drop(1) : @attributes), :rows => rows
        table.style = { :all_separators => true }

        puts table
    end

end