import { apiInitializer } from "discourse/lib/api";
import discourseComputed from "discourse-common/utils/decorators";

export default apiInitializer("1.8.0", (api) => {
  api.registerValueTransformer(
    "header-notifications-avatar-size",
    () => "tiny"
  );

  api.headerIcons.delete("search");

  // api.headerIcons.add("bell-icon", UserAvatarFlair, {
  //   replace: "user-menu", // This should replace the user menu icon
  // });

  api.modifyClass("controller:application", {
    pluginId: "footer-nav-experiment",

    @discourseComputed
    showFooterNav() {
      // mobile, DiscourseHub, PWA (need these for tablets?)
      return (
        this.site.mobileView ||
        this.capabilities.isAppWebview ||
        this.capabilities.isiOSPWA
      );
    },
  });
});
