package;

import Sys;
import haxe.ui.HaxeUIApp;
import haxe.ui.core.Component;
import haxe.ui.macros.ComponentMacros;

class Main {
    public static function main() {
        var args = Sys.args();
        if (args.length < 1) {
            throw "lazy-assets ui cannot launch without an asset type argument";
        }
        var app = new HaxeUIApp();
        app.ready(function() {
            var view:Component = switch (args[0]) {
                case "sprite":
                    ComponentMacros.buildComponent("assets/sprite-view.xml");
                default:
                    throw '${args[0]} is not a supported asset type';
            };
            app.addComponent(view);

            app.start();
        });
    }
}
