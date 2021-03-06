require '/opt/kv-1.2.123/lib/kvclient-1.2.123.jar'
require 'java'
require 'optparse'

java_import 'oracle.kv.KVStore'
java_import 'oracle.kv.KVStoreConfig'
java_import 'oracle.kv.KVStoreFactory'
java_import 'oracle.kv.Key'
java_import 'oracle.kv.Value'
java_import 'oracle.kv.ValueVersion'
java_import 'oracle.kv.Direction'
java_import 'java.util.ArrayList'

def connect(store_name, host_name, port)
    # .to_java converts a Ruby array to a Java array.
    # (:string) specifies the type, otherwise it would be an
    #           array of objects.
    connection_string = host_name + ':' + port
    hosts = [connection_string].to_java(:string)
    begin
        # Use the keyword 'new' for constructors.
        kVStoreConfig = KVStoreConfig.new(store_name, hosts)
        $store = KVStoreFactory.getStore(kVStoreConfig)
        message = "Connected to the Oracle NoSQL store: \"" + $store_name + "\"."
        puts message
        $positiveMessage = "connect: passed"
    rescue Exception => ex
        $errorMessage = "ERROR: Connection to the store: #{ex}"
        puts $errorMessage
        $errorMessage = ""
    end
    return
end

def _prepareKey(keysString)
    # e.g. keysString = "Test/HelloWorld/Java/-/message_text"
    majorComponents = ArrayList.new()
    minorComponents = ArrayList.new()
    keysArray = keysString.split("/")
    isMajor = true
    for i in 0..keysArray.length - 1
        if (keysArray [i] == "-")
            isMajor = false
        end
        if (isMajor)
            majorComponents.add(keysArray [i])
        else
            if (keysArray [i] != "-")
                minorComponents.add(keysArray [i])
            end
        end
    end
    if ((majorComponents.length > 0) & (minorComponents.length > 0))
        myKey = Key.createKey(majorComponents, minorComponents)
    elsif ((majorComponents.length > 0) & (minorComponents.length <= 0))
        myKey = Key.createKey(majorComponents)
    else
        $errorMessage = "ERROR: The String could not be transformed into a Key."
        return
    end
    return myKey
end

def _storeFunctions(what, keysString, valueString)
    myKey = _prepareKey(keysString)
    return if ($errorMessage != "")
    begin
        case what
        when "put"
            myValue = Value.createValue(valueString.to_java_bytes)
            $store.put(myKey, myValue)
        when "get"
            valueVersion = $store.get(myKey)
            if (!valueVersion.nil?)
                valueVersionValueBytes = valueVersion.getValue().getValue()
            else
                puts valueVersion
            end
            myValue = String.from_java_bytes valueVersionValueBytes
            puts myValue
        when "delete"
            myValue = $store.delete(myKey)
            puts myValue
        end
        $positiveMessage = what + ": passed"
    rescue Exception => ex
        $errorMessage = "ERROR: store operation: #{ex}"
        print $errorMessage
        $errorMessage = ""
        return
    end
    return
end

def countAll()
    begin
        # To reference a constant, use ::
        iterator = $store.storeKeysIterator(Direction::UNORDERED, 0)
        i = 0
        while (iterator.hasNext())
            i = i + 1
            iterator.next()
        end
        puts ("Total number of Records: " + i.to_s())
        $positiveMessage = "countAll: passed"
    rescue Exception => ex
        $errorMessage = "ERROR: countAll(): #{ex}"
        puts $errorMessage
        $errorMessage = ""
        return
    end
    return
end

def put(keysString, valueString)
    _storeFunctions("put", keysString, valueString)
    return
end

def get(keysString)
    _storeFunctions("get", keysString, "")
    return
end

def delete(keysString)
    _storeFunctions("delete", keysString, "")
    return
end

def _evalPositiveMessage(what)
    if ($positiveMessage != "")
        puts ($positiveMessage)
        $nFunctionsPassedTest = $nFunctionsPassedTest + 1
    else
        puts(what + ": NOT PASSED")
    end
    $positiveMessage = ""
    $nFunctionsTested = $nFunctionsTested + 1
    return
end

def test(store_name, host_name, port)
    connect(store_name, host_name, port)
    _evalPositiveMessage("connect")
    countAll()
    _evalPositiveMessage("countAll")
    put("MyTest/MComp2/-/mComp1/mComp2","Johannes L�ufer")
    _evalPositiveMessage("put")
    get("MyTest/MComp2/-/mComp1/mComp2")
    _evalPositiveMessage("get")
    delete("MyTest/MComp2/-/mComp1/mComp2")
    _evalPositiveMessage("delete")
    countAll()
    
    puts ($nFunctionsPassedTest.to_s() + " functions passed out of " + 
          $nFunctionsTested.to_s())
end

# Modified from http://ruby.about.com/od/advancedruby/a/optionparser.htm
def parse_arguments()
    optparse = OptionParser.new do|opts|
        # Set a banner at the top of the help screen.
        opts.banner = "Usage: Jruby_oraclenosql.rb [options]"

        opts.on( '-S', '--Store arg', 'Store Name' ) do|arg|
            $store_name = arg
        end

        opts.on( '-H', '--Host arg', 'Host Name') do|arg|
            $host_name = arg
        end
        
        opts.on( '-P', '--Port arg', 'Port') do|arg|
            $port = arg
        end

        $options[:test] = false
        opts.on( '-T', '--test', 'Test') do
            $options[:test] = true
        end        
 
        opts.on( '-h', '--help', 'Help screen') do
            puts opts
            exit
        end
    end
 
    begin
        optparse.parse!
        if ($options[:test]) 
            test($store_name, $host, $port)
        end
    rescue OptionParser::InvalidOption => ex
        #e.recover argv
        puts "ERROR: Unknown argument; " + ex
    end
end

# Ruby's global variables start with $.
$errorMessage = ''
$positiveMessage = ''
$nFunctionsPassedTest = 0
$nFunctionsTested = 0
$myKey
$myValue
$store
$store_name = 'mystore'
$host = 'localhost'
$port = '5000'
# options: command-line parameters.
$options = {}
parse_arguments()


