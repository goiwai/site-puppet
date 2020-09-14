The manifest [`mapping.pp`](mapping.pp) is a snippet to supplement for the class [`storm::mapping`](https://italiangrid.github.io/storm-puppet-module/puppet_classes/storm_3A_3Amapping.html). The manifest `mapping.pp` consists of three parts below:

1. `extraworks`: A class inherited from storm::mapping for giving supplemental works, which enables pool-accounts belonging multiple groups as well as supporting individual roles in the VOMS, like lcgadmin, production.
1. `$pools`: A top-level variable to give a parametrised class `storm::mapping` as well as an internal class `extraworks`.
1. `caller`: A class for calling a class `storm::mapping` with `$pools`, followed by a class `extraworks`.

Perhaps this might feel somebody a bit tricky. The reasons are:

1. Any defined resources can not be redefined. We can override attributes of defined resources inside the inherited class. Therefore, we need a class `extraworks`.
1. We can not instantiate parameters in the base class by giving to inherited class.

To work around these two constraints above, a class `caller` is consequently required. Perhaps there might be a smarter way, though.
