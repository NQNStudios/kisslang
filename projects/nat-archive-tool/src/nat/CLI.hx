package nat;

import kiss.Prelude;
import kiss.List;
import kiss.Operand;
import sys.FileSystem;
import nat.ArchiveController;

using StringTools;

@:build(kiss.Kiss.build())
class CLI implements ArchiveUI {}
