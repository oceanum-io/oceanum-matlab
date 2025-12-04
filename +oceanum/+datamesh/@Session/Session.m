classdef Session < handle
    properties
        id
        user
        creationTime
        endTime
        write
        allowMultiwrite
        verified
        connector
    end
    
    methods
        function obj = Session(data, connector)
            arguments
                data struct
                connector oceanum.datamesh.Connector
            end
            
            obj.connector = connector;
            
            if isfield(data, 'id')
                obj.id = data.id;
            end
            if isfield(data, 'user')
                obj.user = data.user;
            end
            if isfield(data, 'creation_time')
                obj.creationTime = data.creation_time;
            end
            if isfield(data, 'end_time')
                obj.endTime = data.end_time;
            end
            if isfield(data, 'write')
                obj.write = data.write;
            else
                obj.write = false;
            end
            if isfield(data, 'allow_multiwrite')
                obj.allowMultiwrite = data.allow_multiwrite;
            else
                obj.allowMultiwrite = false;
            end
            if isfield(data, 'verified')
                obj.verified = data.verified;
            else
                obj.verified = false;
            end


        end
        
        function headers = addHeader(obj, baseHeaders)
            arguments
                obj
                baseHeaders matlab.net.http.HeaderField
            end
            
            sessionHeader = matlab.net.http.HeaderField('X-DATAMESH-SESSIONID', obj.id);
            headers = [baseHeaders sessionHeader];
        end
        
        % function close(obj, data)
            % arguments
            %     obj
            %     options.finaliseWrite logical = false
            % end
            % 
            % try
            %     uri = matlab.net.URI([obj.connector.getGateway() '/session/' obj.id]);
            %     if options.finaliseWrite
            %         uri.Query = matlab.net.QueryParameter('finalise_write', 'true');
            %     end
            % 
            %     headers = matlab.net.http.HeaderField('X-DATAMESH-SESSIONID', obj.id);
            %     request = matlab.net.http.RequestMessage('DELETE', headers);
            %     response = send(request, uri);
            % 
            %     if response.StatusCode ~= matlab.net.http.StatusCode.NoContent
            %         if options.finaliseWrite
            %             error('oceanum:datamesh:Session:finaliseFailed', ...
            %                 'Failed to finalise write: %s', char(response.StatusCode));
            %         else
            %             warning('oceanum:datamesh:Session:closeFailed', ...
            %                 'Failed to close session: %s', char(response.StatusCode));
            %         end
            %     end
            % catch ME
            %     if options.finaliseWrite
            %         rethrow(ME);
            %     else
            %         warning('oceanum:datamesh:Session:closeFailed', ...
            %             'Failed to close session: %s', ME.message);
            %     end
            % end
        % end
        
        % function delete(obj)
        %     % Destructor - close session when object is destroyed
        %     if ~isempty(obj.id)
        %         obj.close();
        %     end
        % end
    end
    
    % methods (Static)
    %     function session = acquire(connector, varargin)
    %         arguments
    %             connector oceanum.datamesh.Connector
    %             options.allowMultiwrite logical = false
    %         end
    % 
    %         % V1 API only
    %         try
    %             uri = matlab.net.URI([connector.getGateway() '/session/']);
    %             params = connector.getSessionParams();
    %             if options.allowMultiwrite
    %                 params.allow_multiwrite = true;
    %             end
    % 
    %             % Convert params struct to query parameters
    %             queryParams = [];
    %             if ~isempty(params)
    %                 fields = fieldnames(params);
    %                 for i = 1:length(fields)
    %                     queryParams = [queryParams matlab.net.QueryParameter(fields{i}, string(params.(fields{i})))];
    %                 end
    %                 uri.Query = queryParams;
    %             end
    % 
    %             headers = [connector.getAuthHeaders() 
    %                       matlab.net.http.HeaderField('Cache-Control', 'no-store')];
    %             request = matlab.net.http.RequestMessage('GET', headers);
    %             response = send(request, uri);
    % 
    %             if response.StatusCode ~= matlab.net.http.StatusCode.OK
    %                 error('oceanum:datamesh:Session:acquireFailed', ...
    %                     'Failed to create session: %s', char(response.StatusCode));
    %             end
    % 
    %             session = oceanum.datamesh.Session(response.Body.Data, connector);
    % 
    %         catch ME
    %             error('oceanum:datamesh:Session:acquireError', ...
    %                 'Error when acquiring datamesh session: %s', ME.message);
    %         end
    %     end
    % end
end