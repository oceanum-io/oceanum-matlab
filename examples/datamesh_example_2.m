%% This is an exemplar script for using the Oceanum Datamesh API in MATLAB
clc

% Add the parent directory to path so we can access the +oceanum package
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% You can set your Datamesh token by directly passing it into the connector
% or by setting it in your enviroment using:
% setenv("DATAMESH_TOKEN", "your_token")
token = getenv("DATAMESH_TOKEN");
conn = oceanum.datamesh.Connector(token);

%% Example of Get_datasource()
datasource = conn.get_datasource("era5_wind10m");
disp(datasource.variables)

%% Example of query()
query_input = struct( "datasource", "era5_wind10m",...
                       "timefilter", struct("times", ["2023-01-02", "2023-01-02"]), ...
                       "variables", ["u10", "v10"]);
data = conn.query(query_input);

%% Using the data

% Extract the wind components from the queried data
u10 = data.data_vars.u10.data;
v10 = data.data_vars.v10.data;

speed = sqrt(u10.^2 + v10.^2);

long = data.coords.longitude.data;
lat = data.coords.latitude.data;

% Extract 2-D speed field
speed2d = squeeze(speed(1,:,:));   % 721 x 1440

figure
imagesc(long, lat, speed2d)
set(gca, 'YDir', 'normal')          % im