# TODO: Write documentation for `Mt5crystal`
require "json"
require "zeromq"

module MT5API
    VERSION = "0.1.0"

    class Client
        @sys_socket            : ZMQ::Socket
        @data_socket           : ZMQ::Socket
        @indicator_data_socket : ZMQ::Socket
        @chart_data_socket     : ZMQ::Socket

        ###################################################
        ###################################################
        ######################################## Initialize

        def initialize ( host = "localhost" )
            @HOST               = host
            @SYS_PORT           = 15555  # REP/REQ port
            @DATA_PORT          = 15556  # PUSH/PULL port
            @LIVE_PORT          = 15557  # PUSH/PULL port
            @EVENTS_PORT        = 15558  # PUSH/PULL port
            @INDICATOR_DATA_PORT= 15559  # REP/REQ port
            @CHART_DATA_PORT    = 15560  # PUSH port

            # initialise ZMQ context
            @context = ZMQ::Context.new
            
            @sys_socket            = @context.socket( ZMQ::REQ  )
            @data_socket           = @context.socket( ZMQ::PULL )
            @indicator_data_socket = @context.socket( ZMQ::PULL )
            @chart_data_socket     = @context.socket( ZMQ::PUSH )

            # connect to server sockets
            begin
                @sys_socket
                    .connect( "tcp://#{ @HOST }:#{ @SYS_PORT           }"  )
                
                @data_socket
                    .connect( "tcp://#{ @HOST }:#{ @DATA_PORT           }" )
                
                @indicator_data_socket
                    .connect( "tcp://#{ @HOST }:#{ @INDICATOR_DATA_PORT }" )
                
                @chart_data_socket
                    .connect( "tcp://#{ @HOST }:#{ @CHART_DATA_PORT     }" )

            rescue
                raise "Binding ports ERROR"
            end
        end

        ###################################################
        ###################################################
        ################ Connect to socket in a ZMQ context

        def live_socket()
            begin
                socket = @context.socket( ZMQ::PULL )
                socket.connect( "tcp://#{ @HOST }:#{ @LIVE_PORT  }" )

                return socket
            rescue
                raise "Live port connection ERROR"
            end
        end

        ###################################################
        ###################################################
        ################ Connect to socket in a ZMQ context

        def streaming_socket()
            begin
                socket = @context.socket( ZMQ::PULL )
                socket.connect( "tcp://#{ @HOST }:#{ @EVENTS_PORT  }" )

                return socket
            rescue
                raise "Data port connection ERROR"
            end
        end

        ###################################################################
        ###################################################################
        # Construct a request dictionary from default and send it to server

        def construct_and_send( kwargs )
            request = {} of String => Nil | Int32 | Float64 | String | Array( String | Int32 | Float64 )

            [   "action",
                "actionType",
                "symbol",
                "chartTF",
                "fromDate",
                "toDate",
                "id",
                "magic",
                "volume",
                "price",
                "stoploss",
                "takeprofit",
                "expiration",
                "deviation",
                "comment",
                "chartId",
                "indicatorChartId",
                "chartIndicatorSubWindow",
                "style"
            ].each do |key|
                request[ key ] = nil
            end

            # update dict values if exist
            kwargs.each do |key, value|
                if request.has_key?( key )
                    request[ key ] = value
                else
                    raise "Unknown key in **kwargs ERROR"
                end
            end

            # send dict to server
            send_request( request )

            # return server reply
            return pull_reply()
        end

        ###################################################################
        ###################################################################
        # Construct a request dictionary from default and send it to server

        def indicator_construct_and_send( kwargs )
            request = {} of String => Nil | Int32 | Float64 | String | Array( String | Int32 | Float64 )

            [   "action",
                "actionType",
                "id",
                "symbol",
                "chartTF",
                "fromDate",
                "toDate",
                "name",
                "params",
                "linecount"
            ].each do |key|
                request[ key ] = nil
            end

            # update dict values if exist
            kwargs.each do |key, value|
                if request.has_key?( key )
                    request[ key ] = value
                else
                    raise "Unknown key in **kwargs ERROR"
                end
            end

            # send dict to server
            send_request( request )

            # return server reply
            return indicator_pull_reply()
        end

        ###################################################################
        ###################################################################
        # Construct a request dictionary from default and send it to server

        def chart_data_construct_and_send ( kwargs )
            request = {} of String => Nil | Int32 | Float64 | String | Array( String | Int32 | Float64 )

            [   "action",
                "actionType",
                "chartId",
                "indicatorChartId",
                "data"
            ].each do |key|
                request[ key ] = nil
            end

            # update dict values if exist
            kwargs.each do |key, value|
                if message.has_key?( key )
                    message[ key ] = value
                else
                    raise "Unknown key in **kwargs ERROR"
                end
            end

            # send dict to server
            push_chart_data( message )
        end

        #######################################################################
        #######################################################################
        # Send message for chart control to server via ZeroMQ chart data socket

        private def push_chart_data ( data )
            begin
                @chart_data_socket.send_string( data.to_json )
            rescue
                raise "Sending request ERROR"
            end    
        end

        #################################################
        #################################################
        # Send request to server via ZeroMQ System socket

        private def send_request( data )
            begin
                @sys_socket.send_string( data.to_json )

                if ! @sys_socket.receive_string() == "OK"            
                    raise "Something wrong on server side"
                end
            rescue
                raise "Sending request ERROR"
            end
        end

        ####################################################
        ####################################################
        # Get reply from server via Data socket with timeout

        private def indicator_pull_reply()
            begin
                return @indicator_data_socket.receive_string()
            rescue
                raise "Indicator Data socket timeout ERROR"
            end
        end

        ####################################################
        ####################################################
        # Get reply from server via Data socket with timeout

        private def pull_reply()
            begin
                return @data_socket.receive_string()
            rescue
                raise "Data socket timeout ERROR"
            end
        end

    end
end