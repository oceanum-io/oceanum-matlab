classdef Connector
  properties (Access=private)
    token % 
  end
  methods
    function datamesh=Connector(token)
      arguments
        token = ''
      end
      datamesh.token=token
      fprintf("Connector created")
   end
end
