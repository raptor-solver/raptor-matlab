classdef Permutation < raptor.core.scaling.CompositeLinearScaling
    %PERMUTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        what_technique
    end
    
    methods
        function obj = Permutation(cfg, previousScaling)
            % superclass constructor
            if nargin == 0
                super_args = {};
            elseif nargin == 1
                super_args = {cfg};
            elseif nargin == 2
                super_args = {cfg, previousScaling};
            end
            obj@raptor.core.scaling.CompositeLinearScaling(super_args{:});

            % define permutation method
            if nargin >= 1
                obj.what_technique = cfg.technique;
            end
        end
        
        function build(obj, transcription, trajectories)
            % method that builds the row and column permutation matrices to
            % minimize a specific metric to improve factorization speed

            % store the jacobian pattern and variable sizes
            P = transcription.pattern;
            P = spones(double(P));
            [m, n] = size(P);

            % compute matrices depending on specified technique
            switch obj.what_technique
                case "RowColAmd"
                    % apply column permutation
                    q = colamd(P); q = q(:)';
                    A = sparse(1 : n, q, 1, n, n)';

                    % apply row permutation to the already permuted
                    % jacobian
                    p = colamd((P * A')'); p = p(:)';
                    B = sparse(1 : m, p, 1, m, m);
                
                case "DmPerm"
                    % apply dm permutation for rows and columns
                    [p, q] = dmperm(P);
                    p = p(:)'; q = q(:)';
                    A = sparse(1 : n, q, 1, n, n)';
                    B = sparse(1 : m, p, 1, m, m);
                    
                otherwise
                    error("Chosen permutation method not implemented!!");
            end

            % assign the row and column permutation matrices
            obj.B = B;
            obj.A = A;

            % assemble the remaining matrices
            obj.B_inv = inv(obj.B);
            obj.A_inv = inv(obj.A);
            obj.b = zeros(n, 1); obj.b_inv = obj.b;
            obj.D = 1; obj.D_inv = 1;

            % adjust the precomputed pattern
            transcription.pattern = obj.B * P * obj.A';
        end
    end
end