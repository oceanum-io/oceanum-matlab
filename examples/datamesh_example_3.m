%% This is an exemplar script for using the Oceanum Datamesh API in MATLAB
clc

% Add the parent directory to path so we can access the +oceanum package
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% You can set your Datamesh token by directly passing it into the connector
% or by setting it in your enviroment using:
% setenv("DATAMESH_TOKEN", "your_token")
token = getenv("DATAMESH_TOKEN");
conn = oceanum.datamesh.Connector(token);

%% Look for a datasource
catalog = conn.get_catalog("Whanganui");
disp(catalog)

%% Get specifics about datasource
datasource = conn.get_datasource("flowrateconz_whanganui_river");
disp(datasource)
disp(datasource.variables)

%% Query 

query = struct("datasource", "flowrateconz_whanganui_river", ...
    "timefilter", struct("times",["2024-01-1", "2025-01-1"]) ...
    );
data = conn.query(query);

%% Extracting the data and variables

time = datetime(data.coords.time.data, ...
    'InputFormat', 'yyyy-MM-dd''T''HH:mm:ssZ', ...
    'TimeZone','UTC');
rain = data.data_vars.rain.data;
flow = data.data_vars.flow.data; 

%% Plot rain
plot(time,rain);
xlabel("Date")
ylabel("Rainfall (mm)");
title("Rainfall Over Time of Whanganui River");
grid on;


%% Plot FLow
plot(time,flow);
xlabel("Date")
ylabel("River flow")
title("River Flow Over Time of Whanganui River");
grid on;
