# 04 · Brief de la app de asesoramiento (contador + financiero)

Decisiones tomadas antes de diseñar la arquitectura. Sirve de punto de partida para el
documento de arquitectura y no lo reemplaza. Las reglas normativas reflejan lo verificado en
noviembre de 2026 y **deben modelarse como datos versionados por fecha**, no como constantes.

## 1. Objetivo

Que un contratista independiente colombiano que trabaja para empresas del exterior "solo tenga
que trabajar": la app registra el tiempo, factura, calcula y recuerda la seguridad social (PILA)
y el impuesto SIMPLE, reparte el ingreso neto en presupuestos y evalúa la disciplina financiera.
El primer usuario es el dueño del proyecto: persona natural en el Régimen Simple de Tributación
(RST), facturación por horas en USD, ingresos en COP vía TRM.

Decisión abierta: si los módulos de cumplimiento y finanzas son parte del producto multi-tenant
de SHURIKAPP (por ejemplo un plan "Freelancer Pro Colombia") o un producto aparte que consume las
horas facturables por API. Hoy se trabaja sobre este repositorio.

## 2. Módulos

| Módulo | Responsabilidad | Entrega a otros módulos |
|---|---|---|
| **Parámetros normativos** (transversal) | UVT, SMLMV, tarifas, tablas, festivos de Colombia y del país del cliente, conjuntos de reglas por vigencia y escenarios de reforma | Reglas vigentes para una fecha |
| **Trabajo** | Clientes, proyectos, tablero de tareas, time tracker (cada entrada ligada a una tarea) | Horas facturables por cliente y mes |
| **Clientes y contratos** | Contrato, tarifa, moneda, forma de pago, vencimientos; alerta de cláusulas de relación laboral encubierta; concentración por cliente | Tarifa y moneda para facturar |
| **OPEX** | Gastos de la actividad (suscripciones, herramientas) con renovación, moneda y soporte; un proveedor del exterior emite invoice, no factura DIAN | Costo operativo del mes |
| **Facturación** | Borrador = horas × tarifa × TRM → aprobación → proveedor tecnológico → envío desde `billing@` | Ingreso bruto del mes |
| **Tesorería y divisas** | Cuentas, pagos recibidos vs. facturas, TRM real de monetización, comisiones, flujo de caja | Ingreso efectivamente recibido |
| **Cumplimiento** ("el contador") | PILA y SIMPLE con reglas vigentes y escenarios; calendario de vencimientos; obligaciones (ver §9) | Aportes, anticipos, provisión del saldo anual |
| **Finanzas** ("el financiero") | Neto → 30/30/30/10 → presupuestos → gasto real con soporte vs. tope | Alertas de disciplina, avance de metas |
| **Patrimonio e inversiones** | Saldos y rendimientos por inversión, patrimonio neto, metas | Rendimientos → ingresos del SIMPLE |
| **Protección** | Provisión de vacaciones no facturadas, prima y cesantías propias, seguros, plan de pensión | Reservas mensuales |
| **Asesor** | Cierre mensual, alertas, KPIs, paquete para el contador | — |
| **Bóveda** (transversal) | Facturas emitidas y recibidas, planillas PILA, recibos 2593/490, contratos, certificados bancarios, invoices del exterior | Soportes para DIAN/UGPP/contador |

Flujo: Parámetros → Trabajo → Facturación → Tesorería → Cumplimiento → Finanzas →
Patrimonio/Protección → Asesor. Clientes y contratos, OPEX y Bóveda alimentan a todos.

Orden sugerido del MVP: Parámetros, Trabajo (+ OPEX), Facturación, Cumplimiento, Finanzas con
gasto real. Tesorería, Patrimonio, Protección y Asesor en una segunda fase.

KPIs del Asesor: neto real por hora trabajada, % de horas facturables, tasa de ahorro, meses de
cobertura del fondo de emergencia, concentración por cliente.

## 3. Reglas versionadas y escenarios de reforma

Cada norma es un **conjunto de reglas**:

```
RuleSet { nombre, norma_fuente, estado: vigente | aprobada_pendiente | proyecto,
          vigente_desde, vigente_hasta, tablas/parámetros }
```

- **Modo real**: siempre usa los conjuntos `vigente` para la fecha del periodo. Alimenta pagos,
  SIMPLE y presupuestos. No tiene switch.
- **Modo simulación**: un switch *por reforma* muestra, al lado del real, cuánto se pagaría y la
  diferencia. Nunca se usa para registrar pagos.
- Cuando una reforma se aprueba se cambia su estado y fecha; desde ese periodo el modo real la
  usa sin tocar código.
- Cada liquidación guarda el `RuleSet` (y versión) con el que se calculó.

## 4. SIMPLE (RST) — persona natural, servicios profesionales

Fuentes: art. 908 ET; Resolución DIAN 000081 de 2024 (instructivo del formulario 2593);
Concepto DIAN 000024 de 2024; Sentencia C-540 de 2023.

- Grupo: "Grupo 3 «sic» – Servicios profesionales, de consultoría y científicos" (numeral 3 de
  la Ley 2155 de 2021, revivido por la C-540 de 2023).
- **Tabla bimestral** (por ingresos brutos *del bimestre*, en UVT): 0–1.000 → 5,9 %;
  1.000–2.500 → 7,3 %; 2.500–5.000 → 12 %; 5.000–16.666 → 14,5 %.
- **Tabla anual** (declaración anual): 0–6.000 → 5,9 %; 6.000–15.000 → 7,3 %;
  15.000–30.000 → 12 %; 30.000–100.000 → 14,5 %.
- Anticipo (formulario 2593):
  - c.39 ingresos brutos del bimestre (país c.32 + exterior c.33)
  - − c.40 ingresos no constitutivos: aportes obligatorios propios a salud y pensión (arts. 55 y
    56 ET), incluido FSP; la ARL no se resta
  - = c.41 ingresos netos
  - c.36 tarifa: se elige con los ingresos **brutos** del bimestre
  - c.42 anticipo = c.41 × c.36. El ICA consolidado (c.43) va dentro del anticipo
  - Descuentos del 2593: solo aportes a pensión a cargo del empleador (c.45–48)
  - Se restan excedentes (c.51), **nunca el pago del bimestre anterior**
  - Todas las casillas se redondean al múltiplo de $1.000 más cercano
- Declaración anual: tarifa anual elegida con ingresos brutos del año, aplicada a los ingresos
  netos del año; menos descuento del art. 912 (0,5 % de los ingresos recibidos por medios
  electrónicos, con certificado de entidad vigilada por la Superfinanciera; alternativo al
  descuento del GMF, no ambos); menos anticipos pagados.
- **Exención de anticipos** (art. 910 par. 3; Concepto DIAN 2808 de 2025): personas naturales
  con ingresos brutos del año anterior < 3.500 UVT, o inscritas en el año, solo presentan la
  declaración anual hasta que los ingresos del año superen 3.500 UVT; desde ese bimestre pagan
  anticipos. Pendiente confirmar si ese bimestre incluye lo acumulado de los anteriores.
- Tope del régimen: 100.000 UVT. El límite de 12.000 UVT para profesionales (Ley 2277) fue
  declarado inexequible.
- Los rendimientos financieros forman parte de los ingresos brutos del SIMPLE.
- La Ley de Rescate Económico (PL 477 de 2026) no modifica el SIMPLE según el análisis consultado.
- UVT 2026 = $52.374 (Resolución DIAN 000238 de 2025). UVT 2027 aún no publicada.

## 5. PILA — trabajador independiente

Vigente (Ley 100 de 1993 y normas que la modifican):

- IBC = 40 % del ingreso mensual. Contrato de prestación de servicios: sin restar costos.
  Cuenta propia: 40 % del ingreso neto de costos (reales o presuntos, Resolución UGPP 532 de
  2024). Mínimo 1 SMLMV, máximo 25 SMLMV.
- Salud 12,5 %. Pensión 16 %.
- FSP: 1 % de 4 a 16 SMLMV; 1,2 % (16–17); 1,4 % (17–18); 1,6 % (18–19); 1,8 % (19–20);
  2 % (> 20).
- ARL según clase de riesgo (clase I: 0,522 %). Caja de compensación opcional.
- Pago mes vencido; la fecha límite depende de los últimos dígitos del documento.
- Salida hacia el SIMPLE: salud + pensión + FSP del bimestre (c.40). Si cuentan por causación o por pago es el pendiente 2 de §9.

Escenarios (modo simulación):

- **Reforma pensional – Ley 2381 de 2024** (estado: aprobada, pendiente de quedar en firme en la
  Corte; vigencia prevista 1 de abril de 2027, con solicitud de aplazar a 2028): pilar
  contributivo con corte en 2,3 SMLMV; FSP 1,5 % (4–7), 1,8 % (7–11), 2,5 % (11–19),
  2,8 % (19–20), 3 % (> 20).
- **Ley de Rescate Económico – PL 477 de 2026 Cámara** (estado: proyecto, radicado el 29 de
  octubre de 2026; vigencia propuesta 1 de enero de 2027): salud de independientes 12,5 %
  (≤ 2 SMLMV), 13 % (2–4), 13,5 % (4–5), 14 % (5–10), 14,5 % (10–15), 15 % (15–20),
  15,5 % (20–25).

## 6. Facturación electrónica y correo

- El contribuyente del SIMPLE está obligado a facturar electrónicamente. A clientes del exterior,
  normalmente factura de exportación (confirmar con el contador).
- **No integrar directo con la DIAN como software propio** (UBL 2.1, Anexo Técnico 1.9, CUFE,
  firma digital, web services SOAP, set de habilitación de la Resolución 165 de 2023). Usar un
  **proveedor tecnológico con API REST** que firma, valida y devuelve el XML validado y el PDF.
- Envío al cliente: ZIP con el AttachedDocument (XML validado) + PDF, desde `billing@<dominio>`
  (alias de Google Workspace) con la **API de Gmail y OAuth 2.0**: proyecto de Google Cloud con
  pantalla de consentimiento "Interna", alcance `gmail.send` (+ `gmail.readonly` para recepción),
  alias configurado en "Enviar como". Alternativas: SMTP con contraseña de aplicación (2.000/día)
  o SMTP relay por IP. DNS: SPF `include:_spf.google.com`, DKIM de Workspace, DMARC.
- Recepción: `billing@` como correo de recepción de facturas ante la DIAN; filtro de Gmail con
  etiqueta; la app lee los ZIP, extrae NIT, CUFE y total, y guarda el soporte de gasto.

## 7. Finanzas personales

- Ingreso neto = bruto − PILA − anticipo SIMPLE − OPEX (el OPEX se resta **antes** de repartir).
- Reparto 30/30/30/10: Disponible (vida diaria), Ahorro (emergencia, metas, dinero en el
  exterior), Inversión (renta fija, ETF, cuota inicial, emprendimientos pequeños), Ocio. Los
  porcentajes son editables mes a mes.
- Cada bolsa tiene presupuesto por categoría. Superar el tope del mes en cualquier bolsa se marca
  como mala práctica, sin excepción.
- Todo gasto real lleva soporte (factura electrónica o foto).
- Fondo de emergencia: meta en meses de gasto esencial + PILA mínima; al cumplirla, el aporte de
  Ahorro se redirige a las demás metas.
- Provisión mensual para el saldo de la declaración anual del SIMPLE.
- TRM editable (más adelante, cierre oficial automático) y sensibilidad ±10 %.

## 8. Cambios necesarios en el modelo de datos actual (docs/03)

- Nueva entidad `clients` y `contracts` (cliente, tarifa por hora, moneda, vigencia,
  condiciones de pago); `projects` pertenece a un contrato.
- `time_entries` con vínculo a la factura (`invoice_id` y estado `invoiced`) para no cobrar dos
  veces la misma hora.
- `freelancer_profiles.hourly_rate` es del perfil público del marketplace, no la tarifa de
  facturación.

## 9. Pendientes para confirmar con el contador

1. Tipo de cotizante (prestación de servicios vs. cuenta propia) y afiliación a ARL con un
   contratante del exterior.
2. Si los aportes se restan en el bimestre en que se causan o en el que se pagan (mes vencido).
3. Exención de anticipos bajo 3.500 UVT: qué se paga en el bimestre en que se supera.
4. Factura de exportación e IVA de servicios exportados.
5. Aportes voluntarios a pensión obligatoria como ingreso no constitutivo en el SIMPLE.
6. Declaración/registro de activos e inversiones en el exterior.
7. Vigencia de la resolución de numeración de facturación y plazo de conservación de soportes.

## Fuentes

- [Resolución DIAN 000081 de 2024](https://www.dian.gov.co/normatividad/Normatividad/Resoluci%C3%B3n%20000081%20de%2030-04-2024.pdf)
- [DIAN – Régimen Simple de Tributación (tarifas anuales)](https://www.dian.gov.co/impuestos/Regimen-Simple-de-Tributacion-RST/Documents/RST-2024.pdf)
- [Concepto DIAN 000024 de 2024](https://legalytributarioenlinea.co.pwc.com/Repositorio%20PwC/PDF/Doctrina/DIAN/Conceptos/2024/CON-000024-24.pdf)
- [Concepto DIAN 002808 de 2025 – exención de anticipos](https://normograma.dian.gov.co/dian/compilacion/docs/oficio_dian_2808_2025.htm)
- [Resolución DIAN 000238 de 2025 – UVT 2026](https://normograma.dian.gov.co/dian/compilacion/docs/resolucion_dian_0238_2025.htm)
- [Art. 912 ET](https://estatuto.co/912)
- [Actualícese – Aporte a salud 2026](https://actualicese.com/aporte-a-salud-2026-en-el-regimen-contributivo/)
- [Siempre al Día – FSP vigente y Ley 2381](https://siemprealdia.co/colombia/derecho-laboral/aportes-al-fondo-de-solidaridad-pensional/)
- [Siempre al Día – IBC del independiente](https://siemprealdia.co/colombia/derecho-laboral/calculo-del-ibc-de-un-trabajador-independiente/)
- [Vanguardia – Estado de la reforma pensional (nov. 2026)](https://www.vanguardia.com/economia/2026/11/03/que-le-falta-a-la-reforma-pensional-de-2024/)
- [Semana – Ley de Rescate y aportes a salud](https://www.semana.com/economia/macroeconomia/articulo/ley-de-rescate-cambiaria-los-aportes-a-salud-segun-el-salario-asi-pagarian-trabajadores-e-independientes/202649/)
- [Portafolio – Impuestos que cambiaría la Ley de Rescate](https://www.portafolio.co/economia/impuestos/baja-el-umbral-de-renta-suben-tarifas-al-consumo-y-cambia-el-iva-los-impuestos-que-cambiaria-la-ley-de-rescate-505401)
- [DIAN – Requerimientos para ser facturador electrónico](https://micrositios.dian.gov.co/sistema-de-facturacion-electronica/requerimientos-para-ser-facturador-electronico/)
- [Google Workspace – Enviar correo desde una app](https://knowledge.workspace.google.com/admin/gmail/send-email-from-a-printer-scanner-or-app)
- [Gmail API – sendAs](https://developers.google.com/workspace/gmail/api/reference/rest/v1/users.settings.sendAs/create)
