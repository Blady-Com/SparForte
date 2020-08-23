-------------------------------------------------------------------------------
-- NAME (body)                  : spargui-view.adb
-- AUTHOR                       : Pascal Pignard
-- ROLE                         : User interface display unit.
-- NOTES                        : Ada 2012, GNOGA 1.6 beta
--
-- COPYRIGHT                    : (c) Pascal Pignard 2020
-- LICENCE                      : CeCILL V2 (http://www.cecill.info)
-- CONTACT                      : http://blady.pagesperso-orange.fr
-------------------------------------------------------------------------------

package body SparGUI.View is

   ------------
   -- Create --
   ------------

   overriding procedure Create
     (Grid   : in out Default_View_Type; Parent : in out Gnoga.Gui.Base.Base_Type'Class;
      Layout : in Gnoga.Gui.View.Grid.Grid_Rows_Type; Fill_Parent : in Boolean := True; Set_Sizes : in Boolean := True;
      ID     : in     String := "")
   is
   begin
      Gnoga.Gui.View.Grid.Grid_View_Type (Grid).Create (Parent, Layout, Fill_Parent, Set_Sizes, ID);

      Grid.Panel (1, 1).Border;
      Grid.Panel (1, 2).Border;
      --        Grid.Label_Text.Create (Grid.Panel (1, 1).all);
      --  TODO: background light gray
      Grid.Canvas.Create (Grid.Panel (1, 1).all, 400, 400);
      Grid.Application.Create (Grid.Canvas, 400, 400);
      Grid.Renderer.Create (Grid.Application);
      Grid.Container.Create (Grid.Application);
      Grid.Renderer.Auto_Rendering (Grid.Container, True);
      Grid.Turtle.Create (Grid.Container, "img/sparforte.png", 100, 100);
      delay 2.0; --  Wait for image full loaded
      Grid.Turtle.Frame_Limit
        (Grid.Turtle.Row - 50, Grid.Turtle.Row + 50, Grid.Turtle.Column - 50, Grid.Turtle.Column + 50,
         Gnoga.Gui.Plugin.Pixi.Sprite.Bounce_Effect);
      Grid.Turtle.Motion (20.0, 0.0);
      Grid.Graphic.Create (Grid.Container);

--        Grid.Click_Button.Create (Grid.Panel (1, 2).all, "Click Me");
      Grid.Panel (1, 1).New_Line;
      Grid.Exit_Button.Create (Grid.Panel (1, 1).all, "Disconnect");
      Grid.Panel (1, 1).New_Line;
      Grid.Quit_Button.Create (Grid.Panel (1, 1).all, "End SparForte server");

      Grid.Console.Create (Grid.Panel (1, 2).all);
      Grid.Console.Fill_Parent;
      Grid.Console.Show_Gutter;
   end Create;

end SparGUI.View;