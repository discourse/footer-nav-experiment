import { computed } from "@ember/object";
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  // api.registerValueTransformer(
  //   "header-notifications-avatar-size",
  //   () => "tiny"
  // );

  // api.headerIcons.delete("search");

  api.modifyClass(
    "controller:application",
    (Superclass) =>
      class extends Superclass {
        @computed
        get showFooterNav() {
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
