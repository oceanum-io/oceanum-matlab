classdef Stage < handle
    
    % query: Query = Field(title="OceanQL query")
    % qhash: str = Field(title="Query hash")
    % formats: List[str] = Field(title="Available download formats")
    % size: int = Field(title="Request size")
    % dlen: int = Field(title="Domain size")
    % coordmap: dict = Field(title="coordinates map")
    % coordkeys: dict = Field(title="coordinates keys")
    % container: Container = Field(title="Data container type")
    % sig: str = Field(title="Signature hash")
    properties
        query
        qhash
        formats
        size
        dlen
        coordmap
        coordkeys
        container
        sig
    end
    
    methods
        function obj = Stage(data)
            arguments
                data struct
            end
            
            if isfield(data, 'query')
                obj.query = data.query;
            end
            if isfield(data, 'qhash')
                obj.qhash = data.qhash;
            end
            if isfield(data, 'formats')
                obj.formats = data.formats;
            end
            if isfield(data, 'size')
                obj.size = data.size;
            end
            if isfield(data, 'dlen')
                obj.dlen = data.dlen;
            end
            if isfield(data, 'coordmap')
                obj.coordmap = data.coordmap;
            end
            if isfield(data, 'coordkeys')
                obj.coordkeys = data.coordkeys;
            end
            if isfield(data, 'container')
                obj.container = data.container;
            end
            if isfield(data, 'sig')
                obj.sig = data.sig;
            end
        end
        
        function str = char(obj)
            str = sprintf('Stage: %s container', obj.container);
            if ~isempty(obj.size)
                str = sprintf('%s\nSize: %d bytes', str, obj.size);
            end
            if ~isempty(obj.dlen)
                str = sprintf('%s\nData length: %d', str, obj.dlen);
            end
            if ~isempty(obj.formats)
                if iscell(obj.formats)
                    forhttps://datamesh.oceanum.io/oceanq1/stage/mats = strjoin(obj.formats, ', ');
                else
                    formats = jsonencode(obj.formats);
                end
                str = sprintf('%s\nFormats: %s', str, formats);
            end
        end
        
        function disp(obj)
            fprintf('%s\n', char(obj));
        end
        
        function tf = isDataset(obj)
            tf = strcmp(obj.container, 'dataset');
        end
        
        function tf = isDataFrame(obj)
            tf = strcmp(obj.container, 'dataframe');
        end
        
        function tf = isGeoDataFrame(obj)
            tf = strcmp(obj.container, 'geodataframe');
        end
    end
end