classdef PhaseCollocation < handle
    %PHASENUMERIC Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % collocation method
        Polynomials
        Interpolants
        Nodes

        % collocation parameters
        NumberOfNodes
        DynamicTolerance
        TimeDilation
    end

    methods
        function obj = PhaseCollocation()
            % constructor
            obj.Polynomials = "Legendre";
            obj.Interpolants = "Lagrange";
            obj.Nodes = "flipped-Gauss-Radau";
        end

        function obj = polynomials(obj, polynomialsFamily)
            % method that sets the polynomial family for the current phase
            arguments
                obj     raptor.api.v1.elements.numerics.PhaseCollocation
                polynomialsFamily {mustBeMember(polynomialsFamily, ["Legendre"])}
            end
            obj.Polynomials = polynomialsFamily;
        end

        function obj = interpolants(obj, interpolantsFamily)
            % method that sets the interpolants family for the current
            % phase
            arguments
                obj     raptor.api.v1.elements.numerics.PhaseCollocation
                interpolantsFamily {mustBeMember(interpolantsFamily, ["Lagrange", "Birkhoff_a"])}
            end
            obj.Interpolants = interpolantsFamily;
        end

        function obj = nodes(obj, nodesFamily)
            % method that sets the nodes family for the current phase
            arguments
                obj     raptor.api.v1.elements.numerics.PhaseCollocation
                nodesFamily {mustBeMember(nodesFamily, ["Gauss-Radau", "flipped-Gauss-Radau", "Gauss-Lobatto"])}
            end
            obj.Nodes = nodesFamily;
        end

        function obj = numberOfNodes(obj, numberOfNodes)
            % method that sets the number of nodes for the current phase
            arguments
                obj     raptor.api.v1.elements.numerics.PhaseCollocation
                numberOfNodes   {mustBePositive, mustBeInteger}
            end
            obj.NumberOfNodes = numberOfNodes;
        end

        function obj = dynamicTolerance(obj, dynamicTolerance)
            % method that sets the dynamic tolerance for the current phase
            arguments
                obj     raptor.api.v1.elements.numerics.PhaseCollocation
                dynamicTolerance {mustBePositive}
            end
            obj.DynamicTolerance = dynamicTolerance;
        end

        function obj = timeDilation(obj, timeDilationMethod)
            % method that sets the time dilation method for the current
            % phase
            arguments
                obj     raptor.api.v1.elements.numerics.PhaseCollocation
                timeDilationMethod {mustBeMember(timeDilationMethod, ["affine"])}
            end
            obj.TimeDilation = timeDilationMethod;
        end
    end
end

