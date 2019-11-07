classdef myRLExample2B < rl.env.MATLABEnvironment
    %MYRLEXAMPLE1: Template for defining custom environment in MATLAB.    
   %������̬ģ�ͣ�https://blog.csdn.net/u013914471/article/details/82968608
   %�ο��� https://www.mathworks.com/help/releases/R2019b/reinforcement-learning/ug/train-agent-to-control-flying-robot.html
    %% Properties (set properties' attributes accordingly)
    properties
        % initial model state variables
        phi0 = 0;%��ʼ�����
        theta0 = 0;%��ʼǰ��ת��
        x0 = -15;%��ʼXλ��
        y0 = -15;%��ʼYλ��
        vel0 =0;%1m/s
        acc0= 0;
        % sample time
        Ts = 0.1;
        vl = 2.7;%���
        % simulation length
        Tf = 30;
        DisplacementThreshold =1;
        AngleThreshold = 45*pi/180;
        h =0;
       counter = 0;
       reachTarget = 0;
       numEpis = 0;
    end
    
    properties
        % Initialize system state [x,dx,theta,dtheta]'
        State = zeros(9,1)
    end
    
    properties(Access = protected)
        % Initialize internal flag to indicate episode termination
        IsDone = false        
    end

    %% Necessary Methods
    methods              
        % Contructor method creates an instance of the environment
        % Change class name and constructor name accordingly
        function this = myRLExample2B()
            
          
            % Initialize Observation settings
            
            ObservationInfo = rlNumericSpec([7 1]);
            ObservationInfo.Name = 'simple vehicle States';
            ObservationInfo.Description = 'x, dx, y,dy,phi,dphi,vel';
            
            % Initialize Action settings   
            
          ActionInfo = rlNumericSpec([2 1],'LowerLimit',[-0.4;-2],'UpperLimit',[0.4;2]);
       
            % The following line implements built-in functions of RL env
            
            this = this@rl.env.MATLABEnvironment(ObservationInfo,ActionInfo);
  
           
        end
        
        % Apply system dynamics and simulates the environment with the 
        % given action for one step.
        function [Observation,Reward,IsDone,LoggedSignals] = step(this,Action)
             LoggedSignals = [];
             Ts = this.Ts;
             IsDone = false;
%             'x, dx, y,dy,phi, dphi,phi,theta';
            % Get action
          
          
           this.counter =this.counter+1;
           
            Theta = Action(1);%gred2deg     
             acc = Action(2);%gred2deg        
          
            
            % Unpack state vector
            XP = this.State(1);
         
            YP = this.State(3);
          
            PhiP = this.State(5);
          
             velP = this.State(7);      
            
            vel = velP+acc*Ts;
            
            vel = max(0,min(vel,10/3.6));
            
            

            PhiDot = tan(Theta)/this.vl*vel;
            Phi = PhiP+Ts*PhiDot;
            
            XDot=cos(Phi)*vel;
            YDot =sin(Phi)*vel;
            
            X=XP+Ts*XDot;
            Y=YP+Ts*YDot;
            
            
            
            % Euler integration
            Observation =[X;XDot;Y;YDot;Phi;PhiDot;vel];

            % Update system states
            this.State =  [Observation;Theta;acc];
            LoggedSignal.State =  this.State;
            
            % Check terminal condition
            
%             reachTarget = abs(X) < this.DisplacementThreshold && abs(Y) < this.DisplacementThreshold && abs(Phi) < this.AngleThreshold;%Ŀ�ĵ���(0,0).Ŀ��phi =0
             reachTarget = abs(X) < this.DisplacementThreshold && abs(Y) < this.DisplacementThreshold; 
            this.reachTarget  = reachTarget;
            IsDone = reachTarget;
            this.IsDone = reachTarget;
      
            %%%�����뿪Ԥ����Χ
            if  abs(X)>15 || abs(Y)>15
                IsDone = true;
                this.IsDone = true;
            end
            
            
            
            %%%�涨ʱ���ڣ��޷�����Ԥ����
%             dist =sqrt(X^2+Y^2);
%             time1 = dist/(5/3.6);%����Ŀ�ĵ�����Ҫ���ʱ��
%             time2 = this.Tf*10 - this.counter;%���滹ʣ����ʱ��
%               if  time1>time2/10
%                 IsDone = true;
%                 this.IsDone = true;
%             end
            
            % Get reward
            Reward = getReward(this);
            
            % (optional) use notifyEnvUpdated to signal that the 
            % environment has been updated (e.g. to update visualization)
            notifyEnvUpdated(this);
        end
        
        % Reset environment to initial state and output initial observation
        function InitialObservation = reset(this)
            % Theta (+- .05 rad)
            if this.h ~=0
                 close(this.h )
            end
               this.h =figure(randi(10000)) ;
            
           
            Tphi0 = 0;%��ʼ�����
            Ttheta0 = 0;%��ʼǰ��ת��
            Tx0 = this.x0+5*rand();%��ʼXλ��
            Ty0 = this.y0+5*rand();%��ʼYλ��
            Tvel0 =0;%�㶨1m/s
            Tdx0 = Tvel0;
            Tdy0 =0;
            TdPhi0=0;
            Tacc = 0;
            
           
           
            
        
            
            InitialObservation = [Tx0; Tdx0;Ty0;Tdy0;Tphi0;TdPhi0;Tvel0];
            this.State = [InitialObservation;Ttheta0;Tacc];
              this.reachTarget = false;
              this.IsDone = false;
              this.counter =0;
            % (optional) use notifyEnvUpdated to signal that the 
            % environment has been updated (e.g. to update visualization)
%             notifyEnvUpdated(this);
               this.numEpis =this.numEpis+1;
        end
        

    end
    %% Optional Methods (set methods' attributes accordingly)
    methods               
       
        % Reward function
        function Reward = getReward(this)
            XP = this.State(1);
            XDotP = this.State(2);
            YP = this.State(3);
            YDotP = this.State(4);
            PhiP = this.State(5);
            PhiDotP = this.State(6);
          
%              r1 =10*((XP^2+YP^2+PhiP^2)<10);
%              r2 = -100*(abs(XP)>100||abs(YP)>100);
%              r3 = -0.01*ThetaP^2-0.02*XP^2-0.02*YP^2-0.02*PhiP^2;
             
             r1 =500*((abs(XP)<1&&abs(YP)<1));
             r2 =500*((abs(XP)<1&&abs(YP)<1));
             r3 = -XP^2-YP^2-PhiDotP^2;
             r4=-1000*((abs(XP)>15||abs(YP)>15));
              Reward =r1+r2+r3+r4;
%               if Reward >0
%                   pause;
%               end
                

             
        end
        
        % (optional) Visualization method
        function plot(this)
            % Initiate the visualization
            
%             this.h = figure;
            % Update the visualization
             envUpdatedCallback(this)
        end
        
  
        function set.AngleThreshold(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','AngleThreshold');
            this.AngleThreshold = val;
        end
        function set.DisplacementThreshold(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','DisplacementThreshold');
            this.DisplacementThreshold = val;
        end
      
    end
    
    methods (Access = protected) 
        function envUpdatedCallback(this)
            % Set the visualization figure as the current figure
           
             if mod(this.numEpis,50) ~=3
                return;
              end
            
            % Extract the cart position and pole angle
            XP = this.State(1);
            XDotP = this.State(2);
            YP = this.State(3);
            YDotP = this.State(4);
            PhiP = this.State(5);
            PhiDotP = this.State(6);
           
            VelP = this.State(7);
           ThetaP = this.State(8);
           accP = this.State(9);
           
            figure(this.h)
            hold on;
            
            subplot(4,1,1)
            plot(0, 0,'bo');
            plot(XP, YP,'rs');
            xlim([-20 +20])
            ylim([-20 +20])
            title('XP,YP');
              hold off
            
            hold on
            subplot(4,1,2)
            plot(this.counter,rad2deg(ThetaP),'rs' );
            xlim([0 this.counter+100])
            ylim([-30 30])
            title('ThetaP');
              hold off
            
            hold on
            subplot(4,1,3)
            plot(this.counter,accP,'rs' );
            xlim([0 300])
            ylim([-2 2])
            title('accP');
           
            hold off
            
            hold on
            subplot(4,1,4)
            plot(this.counter, VelP,'rs' );
            xlim([0 300])
            ylim([0 10/3.6])
            title('VelP');
            hold off
            
            if this.reachTarget == true
                title('this.reachTarget == true')
            else
                 title('this.reachTarget == false')
            end
          

    
            end
    end
  
end