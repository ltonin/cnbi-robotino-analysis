function varargout = gui_control(varargin)
% GUI_CONTROL MATLAB code for gui_control.fig
%      GUI_CONTROL, by itself, creates a new GUI_CONTROL or raises the existing
%      singleton*.
%
%      H = GUI_CONTROL returns the handle to a new GUI_CONTROL or the handle to
%      the existing singleton*.
%
%      GUI_CONTROL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_CONTROL.M with the given input arguments.
%
%      GUI_CONTROL('Property','Value',...) creates a new GUI_CONTROL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_control_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_control_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui_control

% Last Modified by GUIDE v2.5 29-Nov-2018 14:35:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_control_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_control_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end


% --- Executes just before gui_control is made visible.
function gui_control_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui_control (see VARARGIN)

handles.control.parameters.omega = 0.25;
handles.control.parameters.psi   = 0.7;
handles.scope.run = false;
handles.scope.x = 0:0.0625:10;
handles.scope.y = proc_ringbuffer_init(length(handles.scope.x), 1);
handles.scope.reset_task = false;


handles.distribution.data = load('analysis/bci/aj1_bci_probability.mat');
Ck = handles.distribution.data.labels.sample.Ck;
handles.distribution.task = handles.distribution.data.probability.raw(Ck == 773);
handles.distribution.task = ones(length(handles.distribution.task), 1);

plot_control_force(handles);
plot_control_potential(handles);

set(handles.slider_param_psi, 'Value', handles.control.parameters.psi);
set(handles.param_psi, 'String', num2str(handles.control.parameters.psi, '%4.2f'));

set(handles.slider_param_omega, 'Value', handles.control.parameters.omega);
set(handles.param_omega, 'String', num2str(handles.control.parameters.omega, '%4.2f'));
% 
% x = 0:.01:2*pi;
% y = sin(x);
% handles.sin = y;
% handles.current_data = handles.sin;
% axesHandle = findobj('Tag', 'sin');
% plot(axesHandle, x, y);


% Choose default command line output for gui_control
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gui_control wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end


% --- Outputs from this function are returned to the command line.
function varargout = gui_control_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
handles.scope.run = false;
varargout{1} = handles.output;
end


% --- Executes on slider movement.
function slider_param_psi_Callback(hObject, eventdata, handles)
% hObject    handle to slider_param_psi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderValue = round(get(hObject,'Value')*100)/100;
set(hObject, 'Value', sliderValue);

handles.control.parameters.psi = sliderValue;
set(handles.param_psi, 'String', num2str(handles.control.parameters.psi, '%4.2f'));
guidata(hObject, handles);

plot_control_force(handles);
plot_control_potential(handles);
end






% --- Executes during object creation, after setting all properties.
function slider_param_psi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_param_psi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in reset_task.
function reset_task_Callback(hObject, eventdata, handles)
% hObject    handle to reset_task (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.scope.reset_task = true;
guidata(hObject, handles);
end


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% ---- plot free force
function plot_control_force(handles)

    h = handles.free_force;
    cla(h);
    x = 0:0.001:1;
    support.forcefree.omega  = handles.control.parameters.omega;
    support.forcefree.psi    = handles.control.parameters.psi; 
    Ffree = ctrl_integrator_dynamic_forcefree(x, support.forcefree);
    
    axes(h);
    hold on;
    plot(h, x, Ffree);
    hattr = plot(h, [0 0.5 1], [0 0 0], 'sg', 'MarkerSize', 10);
    hrepl = plot(h, [0.5-support.forcefree.omega 0.5+support.forcefree.omega], [0 0], 'or', 'MarkerSize', 10);
    hold off;
    grid on;
    plot_hline(0, 'k');
    ylim([-1 1]);
    legend(h, [hattr hrepl], 'attractors', 'repellers', 'Location', 'southeast');
    xlabel('y');
    ylabel('F_{free}');
    title('Free Force'); 
end
    
    
% ---- plot free potential
function plot_control_potential(handles)
    
    h = handles.free_potential;
    cla(h);
    x = 0:0.001:1;
    support.forcefree.omega  = handles.control.parameters.omega;
    support.forcefree.psi    = handles.control.parameters.psi; 
    Ffree = ctrl_integrator_dynamic_forcefree(x, support.forcefree);
    Pfree = -cumsum(Ffree);
    
    axes(h);
    plot(x, Pfree);
    grid on;
    %ylim([0 16]);
    xlim([0 1]);
    xlabel('y');
    ylabel('U_{free}');
    title('Free Potential'); 
end


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.scope.run = ~handles.scope.run;

if(handles.scope.run == false)
    set(hObject, 'String', 'Start');
else
    set(hObject, 'String', 'Stop');
end
guidata(hObject, handles);

 h = handles.sin;
axes(h);
support.dt = 0.0625;
support.chi = 2.0;
support.phi = 0.5;
support.forcefree.omega  = 0.25;
support.forcefree.psi    = 0.6;
support.forcebci = [];
data = handles.distribution.task;
prob = [0.5 0.5];

    while(handles.scope.run)
        
        %disp(num2str(num2str(handles.control.parameters.psi, '%4.2f')));
        handles = guidata(hObject);
        
        
        if (handles.scope.reset_task == true)
            prob = [0.5 0.5];
            handles.scope.reset_task = false;
        end
        
        support.forcefree.omega = handles.control.parameters.omega; 
        support.forcefree.psi = handles.control.parameters.psi; 
        
        prob(2) = data(randi(length(data), 1));
        
        sig = ctrl_integrator_dynamic(prob(2), prob(1), support);
        if(sig > 1)
            sig = 1;
        end
        handles.scope.y = proc_ringbuffer_add(handles.scope.y, sig);
        handles.scope.y(isnan(handles.scope.y)) = 0.5;
        
        
        prob(1) = sig;
        
        
       
        
        h = handles.sin;
        axes(h);
        plot(h, handles.scope.x, handles.scope.y);
        plot_hline(0.5, 'k--');
       ylim([-0.1 1.1]);
       %xlim([0 10]);
        %drawnow
        grid on;
        
        
        guidata(hObject, handles);
        pause(0.0625); 
    end
end


% --- Executes on slider movement.
function slider_param_omega_Callback(hObject, eventdata, handles)
% hObject    handle to slider_param_omega (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderValue = round(get(hObject,'Value')*100)/100;
set(hObject, 'Value', sliderValue);

handles.control.parameters.omega = sliderValue;
set(handles.param_omega, 'String', num2str(handles.control.parameters.omega, '%4.2f'));
guidata(hObject, handles);

plot_control_force(handles);
plot_control_potential(handles);
end


% --- Executes during object creation, after setting all properties.
function slider_param_omega_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_param_omega (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end
