import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import htmlClass from "discourse/helpers/html-class";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import { SCROLLED_UP, UNSCROLLED } from "discourse/services/scroll-direction";
import not from "truth-helpers/helpers/not";
import DiscourseURL from "discourse/lib/url";

export default class FooterNavExp extends Component {
  @service appEvents;
  @service capabilities;
  @service scrollDirection;
  @service composer;
  @service modal;
  @service historyStore;
  @service currentUser;
  @service router;

  _modalOn() {
    postRNWebviewMessage("headerBg", "rgb(0, 0, 0)");
  }

  _modalOff() {
    postRNWebviewMessage(
      "headerBg",
      document.documentElement.style.getPropertyValue("--header_background")
    );
  }

  @action
  setDiscourseHubHeaderBg(hasAnActiveModal) {
    if (!this.capabilities.isAppWebview) {
      return;
    }

    if (hasAnActiveModal) {
      this._modalOn();
    } else {
      this._modalOff();
    }
  }

  get hasChatEnabled() {
    console.log(this.currentUser);
    return true;
  }

  @action
  dismiss() {
    postRNWebviewMessage("dismiss", true);
  }

  @action
  goHome() {
    DiscourseURL.routeTo(`/`);
  }

  @action
  goSearch() {
    DiscourseURL.routeTo(`/search`);
  }

  @action
  goChat() {
    DiscourseURL.routeTo(`/chat`);
  }

  @action
  toggleHamburger() {
    this.appEvents.trigger("header:keyboard-trigger", {
      type: "hamburger",
    });
  }

  get isVisible() {
    return (
      [UNSCROLLED, SCROLLED_UP].includes(
        this.scrollDirection.lastScrollDirection
      ) && !this.composer.isOpen
    );
  }

  get currentRouteHome() {
    const routeName = this.router.currentRoute.name;
    return routeName.startsWith("discovery.");
  }

  get currentRouteSearch() {
    return this.router.currentRoute.name === "full-page-search";
  }

  get currentRouteChat() {
    const routeName = this.router.currentRoute.name;
    return routeName.startsWith("chat.");
  }

  <template>
    {{this.setDiscourseHubHeaderBg this.modal.activeModal}}

    {{htmlClass "footer-nav-experiment-present"}}

    {{#if this.capabilities.isIpadOS}}
      {{htmlClass "footer-nav-ipad"}}
    {{else if this.isVisible}}
      {{htmlClass "footer-nav-visible"}}
    {{/if}}

    <div class={{concatClass "footer-nav" (if this.isVisible "visible")}}>
      <div class="footer-nav-widget">
        <DButton
          @action={{this.goHome}}
          @icon="home"
          class="btn-flat btn-large footer-nav__home
            {{if this.currentRouteHome 'active'}}"
          @title="footer_nav.home"
        />

        <DButton
          @action={{this.goSearch}}
          @icon="search"
          class="btn-flat btn-large footer-nav__search
            {{if this.currentRouteSearch 'active'}}"
          @title="footer_nav.search"
        />

        {{#if this.currentUser.can_chat}}
          <DButton
            @action={{this.goChat}}
            @icon="d-chat"
            class="btn-flat btn-large footer-nav__chat
              {{if this.currentRouteChat 'active'}}"
            @title="footer_nav.chat"
          />
        {{/if}}

        <DButton
          @action={{this.toggleHamburger}}
          @icon="bars"
          class="btn-flat btn-large footer-nav__hamburger"
          @title="footer_nav.search"
        />

        {{#if this.capabilities.isAppWebview}}
          <DButton
            @action={{this.dismiss}}
            @icon="chevron-down"
            class="btn-flat btn-large"
            @title="footer_nav.dismiss"
          />
        {{/if}}
      </div>
    </div>
  </template>
}
