classdef Connector
  properties (Access=private)
    _token % 
  end
  methods
    function datamesh=Connector(token)
      arguments
        token = ''
      end
      datamesh._token=token
      fprintf("Connector created")
   end
end
