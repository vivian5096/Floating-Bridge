classdef Cards
    properties(SetAccess = private)
        value
    end
    properties (Access = private)
        image_data
        backimage_data
    end
    methods
         function crd = Cards(value,image_data,backimage_data)
             crd.value = value;
             crd.image_data = image_data;
             crd.backimage_data = backimage_data;
         end
        function img_data = get_Card_Image(crd,side)
            if strcmp(side,'back')
                img_data = crd.backimage_data;
            else 
                 img_data = crd.image_data;
            end
            img_data = (double(flipud(img_data)))/255;
        end
     end
end