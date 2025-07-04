import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import UserDropdown from "discourse/components/header/user-dropdown";
import htmlClass from "discourse/helpers/html-class";
import DAG from "discourse/lib/dag";
import getURL from "discourse/lib/get-url";
import DiscourseURL from "discourse/lib/url";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import Composer from "discourse/models/composer";
import { SCROLLED_UP, UNSCROLLED } from "discourse/services/scroll-direction";
import DMenu from "float-kit/components/d-menu";
import ChatModalNewMessage from "discourse/plugins/chat/discourse/components/chat/modal/new-message";

let headerButtons;
resetHeaderButtons();

function resetHeaderButtons() {
  headerButtons = new DAG({ defaultPosition: { before: "auth" } });
  headerButtons.add("auth");
}

export function headerButtonsDAG() {
  return headerButtons;
}

export function clearExtraHeaderButtons() {
  resetHeaderButtons();
}

export default class FooterNavExp extends Component {
  @service appEvents;
  @service capabilities;
  @service chatStateManager;
  @service composer;
  @service currentUser;
  @service historyStore;
  @service modal;
  @service router;
  @service scrollDirection;
  @service siteSettings;
  @service header;

  @tracked previousURL;

  constructor() {
    super(...arguments);
    this.router.on("routeDidChange", this, this.#updatePreviousURL);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.router.off("routeDidChange", this, this.#updatePreviousURL);
  }

  #updatePreviousURL() {
    if (!this.currentRouteChat) {
      this.previousURL = this.router.currentURL;
    }
  }

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

  get buttonsLength() {
    let count = 2; // home + hamburger

    if (this.showBackButton) {
      count += 1;
    }

    if (this.showChatButton) {
      count += 1;
    }

    // we only show new topic or share, not both at the same time
    if (this.showNewTopicButton || this.showShareButton) {
      count += 1;
    }

    if (this.showDismissButton) {
      count += 1;
    }

    return count;
  }

  get showBackButton() {
    // or limit to this.currentRouteTopic?
    // return this.capabilities.isAppWebview || this.capabilities.isiOSPWA;
    return true;
  }

  get showChatButton() {
    return this.currentUser?.can_chat;
  }

  get showNewTopicButton() {
    return this.currentUser;
    //needs updating for chat and PMs
    // return (
    //   this.currentUser?.can_create_topic &&
    //   settings.include_new_topic_button &&
    //   !this.currentRouteTopic &&
    //   !this.currentRouteChat
    // );
  }

  get showShareButton() {
    return settings.include_new_topic_button && this.currentRouteTopic;
  }

  get showDismissButton() {
    return !this.currentUser && this.capabilities.isAppWebview;
  }

  @action
  dismiss() {
    postRNWebviewMessage("dismiss", true);
  }

  @action
  goHome() {
    if (this.currentRouteChat) {
      const url = getURL(this.previousURL);
      if (url) {
        DiscourseURL.routeTo(url);
      } else {
        DiscourseURL.routeTo(`/`);
      }
    } else {
      DiscourseURL.routeTo(`/`);
    }
  }

  @action
  goChat() {
    // sourced from plugins/chat/assets/javascripts/discourse/components/chat/header/icon.gjs
    if (this.chatStateManager.isFullPageActive) {
      return DiscourseURL.routeTo("/chat");
    }

    DiscourseURL.routeTo(this.chatStateManager.lastKnownChatURL || "/chat");
  }

  @action
  goSearch() {
    return DiscourseURL.routeTo("/search");
  }

  @action
  onRegisterApi(api) {
    this.dMenu = api;
  }

  @action
  toggleHamburger() {
    this.appEvents.trigger("header:keyboard-trigger", {
      type: "hamburger",
    });
  }

  @action
  toggleUserMenu() {
    this.appEvents.trigger("header:keyboard-trigger", {
      type: "user",
    });
  }

  @action
  goNewTopic() {
    if (!this.currentUser?.can_create_topic) {
      return;
    }

    const category = this.router.currentRoute?.attributes?.category;
    const canCreateInCategory = category?.permission;

    this.dMenu.close();
    this.composer.openNewTopic({
      action: Composer.CREATE_TOPIC,
      draftKey: Composer.NEW_TOPIC_KEY,
      category: canCreateInCategory ? category : null,
      tags: this.router.currentRoute?.attributes?.tag?.id,
    });
  }

  @action
  goNewChat() {
    this.dMenu.close();
    next(() => {
      this.modal.show(ChatModalNewMessage);
    });
  }

  @action
  goNewPM() {
    this.dMenu.close();
    this.composer.openNewMessage({});
  }

  get isVisible() {
    return (
      [UNSCROLLED, SCROLLED_UP].includes(
        this.scrollDirection.lastScrollDirection
      ) && !this.composer.isOpen
    );
  }

  get currentRouteHome() {
    const topMenu = this.siteSettings.top_menu.split("|");
    const topMenuRouteNames = topMenu.map((item) => `discovery.${item}`);

    return topMenuRouteNames.includes(this.router.currentRoute.name);
  }

  get currentRouteChat() {
    return this.router.currentRoute.name.startsWith("chat.");
  }

  get currentRouteTopic() {
    return this.router.currentRoute.name.startsWith("topic.");
  }

  get currentRouteSearch() {
    return this.router.currentRoute.name.startsWith("full-page-search");
  }

  get wrapperClassNames() {
    const classes = ["footer-nav"];

    if (this.isVisible) {
      classes.push("visible");
    }

    classes.push(`buttons-${this.buttonsLength}`);

    return classes.join(" ");
  }

  get chatUnreadIndicator() {
    // JIT import because local-dates isn't necessarily enabled
    const ChatIconUnreadIndicator =
      require("discourse/plugins/chat/discourse/components/chat/header/icon/unread-indicator").default;
    return ChatIconUnreadIndicator;
  }

  <template>
    {{this.setDiscourseHubHeaderBg this.modal.activeModal}}

    {{htmlClass "footer-nav-experiment-present"}}

    {{! unclear why we place the footer at the top for ipads? }}
    {{#if this.capabilities.isIpadOS}}
      {{htmlClass "footer-nav-ipad"}}
    {{else if this.isVisible}}
      {{htmlClass "footer-nav-visible"}}
    {{/if}}

    <div class={{this.wrapperClassNames}}>
      <div class="footer-nav-widget">
        <span class="footer-nav__item --menu">
          <DButton
            @action={{this.toggleHamburger}}
            @icon="bars"
            class="btn-flat footer-nav__hamburger"
          />
        </span>

        <span class="footer-nav__item --home">
          <DButton
            @action={{this.goHome}}
            @icon="house"
            class="btn-flat footer-nav__home
              {{if this.currentRouteHome 'active'}}"
          />
        </span>

        {{#if this.showNewTopicButton}}
          <span class="footer-nav__item --new">
            <DMenu
              @identifier="new-menu"
              @title="new"
              @icon="plus"
              @class="btn-transparent footer-nav__new-topic"
              @onRegisterApi={{this.onRegisterApi}}
              @modalForMobile={{true}}
            >
              <:content>
                <DropdownMenu as |dropdown|>
                  <dropdown.item>
                    {{#if this.currentUser.can_create_topic}}
                      <DButton
                        @label={{themePrefix "mobile_footer.new_topic"}}
                        @action={{this.goNewTopic}}
                        @icon="far-pen-to-square"
                        class="btn-transparent
                          {{if
                            this.currentUser.can_create_topic
                            ''
                            'disabled'
                          }}"
                      />
                    {{/if}}
                  </dropdown.item>
                  {{#if this.currentUser.can_chat}}
                    <dropdown.item>
                      <DButton
                        @label={{themePrefix "mobile_footer.new_chat"}}
                        @action={{this.goNewChat}}
                        @icon="comment"
                        class="btn-transparent"
                      />
                    </dropdown.item>
                  {{/if}}
                  {{#if this.currentUser.can_direct_message}}
                    <dropdown.item>
                      <DButton
                        @label={{themePrefix "mobile_footer.new_pm"}}
                        @action={{this.goNewPM}}
                        @icon="envelope"
                        class="btn-transparent"
                      />
                    </dropdown.item>
                  {{/if}}
                </DropdownMenu>
              </:content>
            </DMenu>
          </span>
        {{/if}}

        {{#if this.showChatButton}}
          <span class="footer-nav__item --chat">
            <DButton
              @action={{this.goChat}}
              @icon="d-chat"
              @title="footer_nav.chat"
              class="btn-flat footer-nav__chat
                {{if this.currentRouteChat 'active'}}"
            />
            {{this.chatUnreadIndicator}}
          </span>
        {{/if}}

        {{#if this.currentUser}}
          <span class="footer-nav__item --user">
            <UserDropdown
              @active={{this.header.userVisible}}
              @toggleUserMenu={{this.toggleUserMenu}}
            />
          </span>
        {{/if}}

        {{#if this.showDismissButton}}
          <span class="footer-nav__item --hub">
            <DButton
              @action={{this.dismiss}}
              @icon="fab-discourse"
              @title={{themePrefix "mobile_footer.return_to_hub"}}
              class="btn-transparent no-text"
            />
          </span>
        {{/if}}

      </div>
    </div>
  </template>
}
