%% This is an exemplar script for using the Oceanum Datamesh API in MATLAB
clc

% Add the parent directory to path so we can access the +oceanum package
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% You can set your Datamesh token by directly passing it into the connector
% or by setting it in your enviroment using:
% setenv("DATAMESH_TOKEN", "your_token")
conn = oceanum.datamesh.Connector();

% Once Connector is set as a variable in your enviroment the object can be
% used to access the Datamesh API using various methods such as
% get_catalog, get_datasource, and query.

%% The get_catalog returns all the datasets which contain the keyword
% inputted. For example:
catalog = conn.get_catalog("oceanum");
disp(catalog)

%% After finding a specific datasource, you can pull more information about
% the datasource using get_datasoource("datasource_ID")

datasource_info = conn.get_datasource("oceanum-sea-level-rise");
disp(datasource_info)
disp(datasource_info.variables) % Show datasource variables 

%% To load the data into our workbench and workspace we can use the Query
% method to pull specific parts of the data such as variables or
% timeranges.

query = struct( "datasource", "oceanum-sea-level-rise"); 
data = conn.query(query);

%% Now that the data's been loaded in, we can view it in our work space.
% By default the datasource should be a structure as that has the best
% compatibility with MATLAB.

Days = data.data_vars.Day.data;
sea_level_rise_average = data.data_vars.sea_level_rise_average.data;

x = datetime(Days);
y = sea_level_rise_average;

figure
hold on
plot(x, y, '.', 'MarkerSize', 12)
xtickformat("dd-MMM-yyyy")

xlabel('Time')
ylabel('Average sea level rise')
title('Oceanum Sea level rise example')
grid on