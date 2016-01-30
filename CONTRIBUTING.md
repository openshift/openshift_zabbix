OpenShift-Zabbix Contributor Guidelines
=======================================

* [Summary](#summary)
* [Communication](#communication)
    * [Google+](#google)
    * [IRC](#irc)
    * [Mailing list](#mailing-list)
    * [Twitter](#twitter)
* [Conventions](#conventions)

Summary
=======

For any project with more than a handful of contributors, it is helpful to
agree on some guidelines for participation. This document walks through
various expectations that have developed for the OpenShift project(s).

With awareness that any open source project guidelines must sometimes bend to
allow specific circumstances, we hope these will be useful guidelines for
making this project successful. That also means guidelines should be limited in
order to avoid becoming TL;DR.

Communication
=============

Because this repository contains monitoring checks that are often developed as
a result of operational experiences, there is an inherently iterative and
contextual nature to the code. OpenShift operations team members are happy to
help and guide you in making the best use of this respository.

### Google+ ###

The OpenShift Origin community central coordination point is our
[Google+ community](https://plus.google.com/communities/114361859072744017486).
Join for news and Q/A.

### IRC ###

OpenShift developers and operations staff discuss the project in realtime on [#openshift-dev on
freenode](http://webchat.freenode.net/?randomnick=1&channels=openshift-dev&uio=d4).

### Mailing list ###

The OpenShift developer mailing list is <dev@lists.openshift.redhat.com> - you
may join freely at
<https://lists.openshift.redhat.com/openshiftmm/listinfo/dev>.

### Twitter ###

Follow [@openshift](https://twitter.com/openshift) and
[@openshift\_ops](https://twitter.com/openshift_ops) on Twitter.

Conventions
===========

In general, the primary guideline is to follow the best practices for the
languages and tools being used.

### Languages ###

The default language for the OpenShift Zabbix checks is Ruby. Unless there's a
specific reason, all new checks should use Ruby.

e.g. interfacing with ActiveMQ requires running within the JVM, which
means the ActiveMQ check uses Java to collect its metrics.

### File Naming ###

* Check scripts should omit an extension. (i.e. no '.rb')
* Libraries should follow Ruby best practices for file naming.
  (i.e.  snake\_case.rb)
