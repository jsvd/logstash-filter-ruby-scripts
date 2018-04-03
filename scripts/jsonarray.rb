# Parse Array of JSON objects, this is useful when the logstash JSON filter encounters a list/array of objects/fields whcih Kibana doesnt do great with  which use key/value pairs to describe items eg
# [{ "name" => "useragent" , "value" => "YOUR USERAGENT STRING")]
# Developed on Office 365 audit logging

def register(params)
   @sourceField = params["sourceField"]
   @nameField = params["nameField"]
   @valueField = params["valueField"]
   @dest = params["dest"]
end

def filter(event)
  object = event.get(@sourceField)
  h = {}
  for thing in object
    itemName = thing[@nameField]
    itemValue = thing[@valueField]
    h[itemName] = itemValue
  end
  event.set(@dest, h)
  return [event]
end
