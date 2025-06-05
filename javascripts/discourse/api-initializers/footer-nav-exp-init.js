import { apiInitializer } from "discourse/lib/api";
import discourseComputed from "discourse/lib/decorators";

export default apiInitializer("1.8.0", (api) => {
  // api.registerValueTransformer(
  //   "header-notifications-avatar-size",
  //   () => "tiny"
  // );

  // api.headerIcons.delete("search");

  api.modifyClass(
    "controller:application",
    (Superclass) =>
      class extends Superclass {
        @discourseComputed
        showFooterNav() {
          // mobile, DiscourseHub, PWA (need these for tablets?)
          return (
            this.site.mobileView ||
            this.capabilities.isAppWebview ||
            this.capabilities.isiOSPWA
          );
        }
      }
  );
});
